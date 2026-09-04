"""Structured Gemini inference for food labels and Indian street foods."""

import asyncio
import json
import logging
import re
from typing import Any, Optional, Type

from google import genai
from google.genai import types
from google.genai.errors import APIError

from app.core.config import settings
from app.schemas.food import GeminiFoodExtractionSchema

logger = logging.getLogger("aaharai.gemini")


SCHEMA_INSTRUCTION = (
    "\n\nCRITICAL RESPONSE FORMAT: You MUST return a single JSON object matching this schema:\n"
    "{\n"
    '  "food_name": "string (name of food item or dish)",\n'
    '  "brand_name": "string or null",\n'
    '  "serving_size": "string or null",\n'
    '  "nutrients": {\n'
    '    "calories": float (energy in kcal),\n'
    '    "protein_g": float,\n'
    '    "carbs_g": float,\n'
    '    "fat_g": float,\n'
    '    "saturated_fat_g": float or null,\n'
    '    "added_sugar_g": float or null,\n'
    '    "sodium_mg": float or null,\n'
    '    "fiber_g": float or null\n'
    "  },\n"
    '  "parsed_ingredients": [\n'
    "    {\n"
    '      "name": "string (ingredient name)",\n'
    '      "ins_code": "string or null (e.g. INS 322)",\n'
    '      "safety": "safe" | "moderate" | "avoid",\n'
    '      "plain_explanation": "string (plain language explanation)",\n'
    '      "regulatory_footnote": "string or null (FSSAI/ICMR baseline)"\n'
    "    }\n"
    "  ],\n"
    '  "allergens": ["string (e.g. Milk, Soy, Gluten, Peanuts)"],\n'
    '  "preparation_insights": "string or null"\n'
    "}\n"
    "Return valid JSON only."
)


class GeminiInferenceService:
    def __init__(self) -> None:
        self._client: Optional[genai.Client] = None
        self.model_name = settings.GEMINI_MODEL_NAME
        self.system_instruction = settings.SYSTEM_INSTRUCTION
        self.request_timeout_seconds = 30.0

    @property
    def client(self) -> genai.Client:
        if self._client is None:
            self._client = genai.Client(
                api_key=settings.GEMINI_API_KEY.get_secret_value()
            )
        return self._client

    @staticmethod
    def _clean_json_text(text: str) -> str:
        cleaned = text.strip()
        if "```json" in cleaned:
            parts = cleaned.split("```json")
            cleaned = parts[1].split("```")[0]
        elif "```" in cleaned:
            parts = cleaned.split("```")
            cleaned = parts[1]

        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start != -1 and end != -1 and end > start:
            cleaned = cleaned[start : end + 1]

        cleaned = re.sub(r",\s*([\]}])", r"\1", cleaned)
        return cleaned.strip()

    async def _execute_with_retry(
        self,
        contents: Any,
        schema: Type[GeminiFoodExtractionSchema] = GeminiFoodExtractionSchema,
        max_retries: int = 3,
    ) -> GeminiFoodExtractionSchema:
        delay = 1.5
        last_exception: Optional[Exception] = None

        candidate_models = list(
            dict.fromkeys([
                "gemini-3.5-flash",
                "gemini-3.5-flash-lite",
                self.model_name,
                "gemini-flash-latest",
            ])
        )

        for attempt in range(1, max_retries + 1):
            current_model = candidate_models[(attempt - 1) % len(candidate_models)]
            try:
                response = await asyncio.wait_for(
                    asyncio.to_thread(
                        self.client.models.generate_content,
                        model=current_model,
                        contents=contents,
                        config=types.GenerateContentConfig(
                            system_instruction=self.system_instruction + SCHEMA_INSTRUCTION,
                            temperature=0.1,
                            response_mime_type="application/json",
                        ),
                    ),
                    timeout=self.request_timeout_seconds,
                )
                response_text = getattr(response, "text", None)
                if not response_text:
                    raise ValueError("Empty response text received from Gemini API")

                sanitized_json = self._clean_json_text(response_text)
                return schema.model_validate(json.loads(sanitized_json))
            except asyncio.TimeoutError as exc:
                last_exception = exc
                logger.warning(
                    "Gemini API model %s timed out after %.1fs (attempt %d/%d)",
                    current_model,
                    self.request_timeout_seconds,
                    attempt,
                    max_retries,
                )
            except APIError as exc:
                last_exception = exc
                code = getattr(exc, "code", None)
                is_transient = (
                    code in (429, 500, 502, 503, 504)
                    or "RESOURCE_EXHAUSTED" in str(exc)
                    or "UNAVAILABLE" in str(exc)
                    or "DEADLINE_EXCEEDED" in str(exc)
                )
                if not is_transient:
                    raise
                logger.warning(
                    "Gemini model %s transient error (%s); backing off %.1fs to next candidate model (attempt %d/%d)",
                    current_model,
                    code or str(exc),
                    delay,
                    attempt,
                    max_retries,
                )
            except (ValueError, TypeError, json.JSONDecodeError) as exc:
                last_exception = exc
                logger.warning(
                    "Gemini model %s response validation failed (attempt %d/%d): %s",
                    current_model,
                    attempt,
                    max_retries,
                    exc,
                )
            except Exception as exc:
                last_exception = exc
                logger.warning(
                    "Gemini model %s inference failed (attempt %d/%d): %s",
                    current_model,
                    attempt,
                    max_retries,
                    exc,
                )


            if attempt < max_retries:
                await asyncio.sleep(delay)
                delay *= 2.0

        raise RuntimeError(
            f"Gemini service failed after {max_retries} attempts: {last_exception}"
        ) from last_exception

    async def parse_ingredients_text(
        self,
        food_name: str,
        raw_ingredients: str,
        existing_nutrients: Optional[dict] = None,
    ) -> GeminiFoodExtractionSchema:
        prompt = f"""Product Name: {food_name}
Raw Ingredients Text: {raw_ingredients}
Known Baseline Nutrients: {json.dumps(existing_nutrients) if existing_nutrients else "None"}

Identify each ingredient, resolve INS numbers using FSSAI references, assign safe/moderate/avoid,
explain each item in plain language, and list allergens from Milk, Gluten/Wheat, Soy,
Tree Nuts, Peanuts, Egg, Fish, and Crustaceans."""
        return await self._execute_with_retry(prompt)

    async def extract_from_image_bytes(
        self, image_bytes: bytes, mime_type: str = "image/jpeg"
    ) -> GeminiFoodExtractionSchema:
        image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
        prompt = (
            "Analyze this food packaging image strictly based ONLY on the visible text, brand logos, ingredients, and nutrition details.\n"
            "Carefully read Hindi (Devanagari script), English, and Indian regional languages (e.g. 'बाल पुष्टिकर', 'आटा बेसन बर्फी प्रीमिक्स', 'नेफेड' / NAFED, '3-6 वर्ष आयु वर्ग के बच्चों के लिए', 'बाल विकास एवं पुष्टाहार विभाग').\n"
            "Extract the exact product name, brand name, nutritional profile per 100g (or realistic ICMR-NIN baseline for this recipe if numbers are partially occluded), deconstructed ingredients (with plain conversational English explanations and safety ratings), and allergens.\n"
            "CRITICAL ANTI-HALLUCINATION RULE: Never invent unrelated commercial food products (such as Maggi or instant noodles). Ground your analysis strictly in the actual product shown in the image. If the image is a QR code, barcode, or non-food surface without packaging, identify it accurately rather than fabricating food details."
        )
        return await self._execute_with_retry([image_part, prompt])

    async def estimate_street_food(
        self, dish_name: str, region: str = "India"
    ) -> GeminiFoodExtractionSchema:
        prompt = f"""Indian street food dish: {dish_name} (region: {region})
Estimate nutrients per standard serving using ICMR-NIN IFCT 2017 baselines.
Deconstruct standard preparation ingredients and highlight hidden preparation insights
such as repeatedly heated oil or high-sodium sauces."""
        return await self._execute_with_retry(prompt)

    async def resolve_barcode_item(
        self, barcode: str
    ) -> Optional[GeminiFoodExtractionSchema]:
        prompt = f"""Identify the Indian packaged food item associated with barcode '{barcode}'.
If this barcode corresponds to a known Indian food or beverage SKU, provide the exact food name,
brand name, serving size, FSSAI nutritional values per 100g, and deconstructed ingredients with safety ratings.
If this barcode is not a known food product, set food_name to 'Unidentified Item'."""
        try:
            return await self._execute_with_retry(prompt)
        except Exception:
            return None


gemini_service = GeminiInferenceService()
