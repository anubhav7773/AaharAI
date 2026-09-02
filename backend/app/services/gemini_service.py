"""Structured Gemini inference for food labels and Indian street foods."""

import asyncio
import json
import logging
from typing import Any, Optional, Type

from google import genai
from google.genai import types
from google.genai.errors import APIError

from app.core.config import settings
from app.schemas.food import GeminiFoodExtractionSchema

logger = logging.getLogger("aaharai.gemini")


class GeminiInferenceService:
    def __init__(self) -> None:
        self.client = genai.Client(
            api_key=settings.GEMINI_API_KEY.get_secret_value()
        )
        self.model_name = settings.GEMINI_MODEL_NAME
        self.system_instruction = settings.SYSTEM_INSTRUCTION

    async def _execute_with_retry(
        self,
        contents: Any,
        schema: Type[GeminiFoodExtractionSchema] = GeminiFoodExtractionSchema,
        max_retries: int = 3,
    ) -> GeminiFoodExtractionSchema:
        delay = 2.0
        last_exception: Optional[Exception] = None

        for attempt in range(1, max_retries + 1):
            try:
                response = await asyncio.to_thread(
                    self.client.models.generate_content,
                    model=self.model_name,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        system_instruction=self.system_instruction,
                        temperature=0.1,
                        response_mime_type="application/json",
                        response_schema=schema,
                    ),
                )
                response_text = getattr(response, "text", None)
                if not response_text:
                    raise ValueError("Empty response text received from Gemini API")
                return schema.model_validate(json.loads(response_text))
            except APIError as exc:
                last_exception = exc
                code = getattr(exc, "code", None)
                if code != 429 and "RESOURCE_EXHAUSTED" not in str(exc):
                    raise
                logger.warning(
                    "Gemini quota hit; backing off %.1fs (attempt %d/%d)",
                    delay,
                    attempt,
                    max_retries,
                )
            except (ValueError, TypeError, json.JSONDecodeError) as exc:
                last_exception = exc
                logger.warning(
                    "Gemini response validation failed (attempt %d/%d): %s",
                    attempt,
                    max_retries,
                    exc,
                )
            except Exception as exc:
                last_exception = exc
                logger.warning(
                    "Gemini inference failed (attempt %d/%d): %s",
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
            "Analyze this food label. Extract the product, serving nutrients, ingredients, "
            "plain-language safety explanations, and allergen warnings."
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


gemini_service = GeminiInferenceService()
