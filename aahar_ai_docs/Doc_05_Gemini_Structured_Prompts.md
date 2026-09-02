# Doc 05: Gemini 2.5 Flash Structured Prompting & Token Optimizer

## 1. Architectural Foundations & Free-Tier Quota Engineering
- **Target Model**: `gemini-2.5-flash` via official `google-genai` SDK.
- **Output Guarantee**: Guaranteed JSON conformance using `response_mime_type="application/json"` combined with strict `response_schema`. Eliminates markdown wrapper fences (e.g. ````json ... ````) and conversational hallucination.
- **Deterministic Calibration**: `temperature=0.15` to `0.2` for factual, repeatable regulatory analysis.
- **Quota Scope**:
  - Limits are bound at the **Google Cloud Project level**, not per individual API key[cite: 2]. Generating multiple keys under the same project does not increase RPM/RPD[cite: 2].
  - Daily request counters (RPD) reset at **Midnight Pacific Time (PT)**[cite: 2].
  - Client-side token compression prevents reaching Token-Per-Minute (TPM) ceilings[cite: 2].

---

## 2. Image Token Dynamics & Resolution Optimization

Gemini calculates vision tokens based on image pixel dimensions and slicing tiles[cite: 2]:

### 2.1 Resolution & Tile Cost Rules
- **Base Tile Rule**: Images with both dimensions $\le 384\text{px}$ cost a flat **258 tokens**[cite: 2].
- **Large Image Slicing**: Images larger than $384\text{px}$ are split into $768 \times 768\text{px}$ tiles, each consuming **258 tokens**[cite: 2].
  - *Crop Unit Formula*: $\text{Tile Unit} = \lfloor \min(\text{width}, \text{height}) / 1.5 \rfloor$[cite: 2].
  - A standard full-size phone photo ($4000 \times 3000\text{px}$) can consume thousands of tokens and easily trigger free-tier `429 RESOURCE_EXHAUSTED`[cite: 2].

### 2.2 Client-Side Preprocessing Pipeline
Before sending camera frames to the backend, Flutter must downsample images[cite: 2]:
1. **Target Bounds**: Max width $1024\text{px}$, max height $1024\text{px}$ (generates 1 to 4 tiles max $\approx 258 - 1032$ tokens), keeping text razor-sharp for fine-print ingredient lists[cite: 2].
2. **Quality Cap**: JPEG encoding at 80% quality.
3. **Payload Type**: Transmitted as transient Base64/raw bytes (Inline data payload strictly capped below 20 MB)[cite: 2].

---

## 3. Universal System Instruction (`SYSTEM_INSTRUCTION`)

Antigravity must inject this exact string into all `google-genai` client configurations[cite: 2]:

```text
You are the expert Indian Food Science and Labelling Intelligence Engine for AaharAi.

PRIMARY GOALS:
1. Translate complex chemical names and FSSAI International Numbering System (INS) codes into 100% plain, conversational, everyday language for an average Indian consumer ("Aam Aadmi").
2. Adhere strictly to FSSAI (Labelling and Display) Regulations 2020:
   - Identify the descending order of ingredients (the first 3 items form the bulk of the food).
   - Detect and flag the 8 statutory allergen categories: Milk, Gluten Cereals (Wheat/Barley/Oats), Soy, Nuts/Peanuts, Eggs, Fish, Crustaceans, Sulphites.
3. For unpacked Indian street foods, estimate nutritional facts per 100g anchored against the Indian Food Composition Tables (IFCT 2017). Highlight hidden processing factors (e.g. repeated frying oil degradation/TPC, sodium/MSG saturation, refined maida density).
4. Strictly categorize every deconstructed ingredient into one of three safety tiers:
   - 'safe': Natural, non-toxic, standard food items, or additives well within standard GMP without warning triggers.
   - 'moderate': Synthetic additives, refined sugars/syrupy sweeteners, or additives with strict Acceptable Daily Intake (ADI) caps.
   - 'avoid': Additives banned in infant foods, heavy metal risk carriers, high-concern artificial colors, synthetic trans-fats, or allergens with high sensitivity.

SAFETY & COMPLIANCE GUARDRAIL:
- Never provide medical diagnoses, clinical treatments, or drug-equivalent therapeutic claims.
- Strictly avoid words: 'cure', 'treatment', 'disease reversal', 'prevent illness', 'increase lifespan'.
- Keep tone informative, objective, and empowering, not alarmist.
4. Schema Architecture for Structured Output
Antigravity uses these Pydantic models with response_schema to enforce type-safe JSON returns[cite: 2]:

Python
from pydantic import BaseModel, Field
from typing import List, Optional, Literal

class DeconstructedIngredient(BaseModel):
    name: str = Field(
        ..., 
        description="Standard generic name or INS code (e.g., 'INS 102 - Tartrazine', 'Palm Oil', 'Maida')"
    )
    simple_explanation: str = Field(
        ..., 
        description="A simple 1-line explanation of what this ingredient is and why it was put into the food."
    )
    category: Literal["safe", "moderate", "avoid"] = Field(
        ..., 
        description="Safety rating of the ingredient based on FSSAI thresholds and additive concerns."
    )
    health_note: str = Field(
        ..., 
        description="Clear factual advisory or regulatory restriction (e.g., 'ADI capped at 7.5mg/kg', 'Synthetic dye prohibited in baby foods')."
    )

class MacroNutrients(BaseModel):
    calories_100g: float = Field(..., description="Estimated or declared energy in kcal per 100g")
    protein_100g: float = Field(..., description="Protein in grams per 100g")
    carbs_100g: float = Field(..., description="Total carbohydrates in grams per 100g")
    fat_100g: float = Field(..., description="Total fat in grams per 100g")
    fiber_100g: float = Field(0.0, description="Dietary fiber in grams per 100g")

class FoodAnalysisSchema(BaseModel):
    food_name: str = Field(..., description="Accurate name of the food item or dish")
    brand_name: Optional[str] = Field(None, description="Commercial brand name if identified on packaging")
    nutrients: MacroNutrients = Field(..., description="Nutritional profile per 100g edible portion")
    allergens_detected: List[str] = Field(
        default_factory=list, 
        description="FSSAI statutory allergens present (Wheat/Gluten, Milk, Soy, Nut, Egg, Fish, Crustacean, Sulphite)"
    )
    ingredients: List[DeconstructedIngredient] = Field(
        ..., 
        description="Comprehensive list of deconstructed ingredients in descending order of presence"
    )
    preparation_insights: Optional[str] = Field(
        None, 
        description="Street food or processing phase insights (e.g., oil oxidation, deep-frying absorption, starch concentration)"
    )
5. Flow-Specific Production Prompt Templates
5.1 Prompt 1: Barcode Ingredient Text Translation
Used after Open Food Facts returns the raw ingredients_text[cite: 2]:

Python
def build_barcode_text_prompt(product_name: str, brand: str, raw_ingredients: str, nutriments: dict) -> str:
    return f"""
Analyze this packaged product sold in the Indian market:
- Product Name: {product_name}
- Brand: {brand or 'Not Specified'}
- Declared Ingredients List: "{raw_ingredients}"
- Authority Nutriments per 100g:
  Calories: {nutriments.get('energy-kcal_100g', 'Unknown')} kcal
  Protein: {nutriments.get('proteins_100g', 0)}g
  Carbohydrates: {nutriments.get('carbohydrates_100g', 0)}g
  Fat: {nutriments.get('fat_100g', 0)}g
  Fiber: {nutriments.get('fiber_100g', 0)}g

TASK:
1. Deconstruct every single ingredient and chemical additive (INS number) in the order listed.
2. Provide a 1-sentence plain-language explanation for every molecule.
3. Identify all FSSAI statutory allergens declared or implied.
4. Verify or populate standard nutrient values per 100g based on the declared values above.
"""
5.2 Prompt 2: Multimodal OCR Back-of-Pack Label Scan
Used when the user photographs the physical ingredient box[cite: 2]:

Python
MULTIMODAL_VISION_PROMPT = """
Inspect the provided image of a packaged food label:
1. Locate and OCR the "Ingredients" or "List of Ingredients" section.
2. Locate the "Nutritional Information" / "Nutrition Facts" panel.
3. Extract all ingredients in strictly descending order, identifying parenthetical sub-ingredients and INS numbers.
4. Read per 100g values for Calories, Protein, Carbs, Fat, and Fiber (calculate or normalize from per-serving values if only serving size is given).
5. Detect any allergen statements (e.g., 'Contains Wheat, Milk' or 'May Contain Traces of Soy').
6. Deconstruct all molecules into simple everyday language with safe/moderate/avoid flags.

If the image is blurry, partial, or illegible, parse what is visible and explicitly note limitations in the first ingredient's health note.
"""
5.3 Prompt 3: Unpacked Indian Street Food Breakdown
Used for dishes without barcodes or packages (Chowmein, Samosa, Momos, etc.):  
MD
+ 1

Python
def build_street_food_prompt(dish_name: str) -> str:
    return f"""
Analyze the standard preparation of the Indian street food dish: '{dish_name}'.

TASK:
1. Estimate nutritional values per 100g cooked portion using Indian Food Composition Tables (IFCT 2017) benchmarks.
2. Break down the typical raw composite ingredients (e.g., refined maida flour, commercial frying fat, sodium, cabbage, onions).
3. In 'preparation_insights', explain the commercial reality of how roadside vendors prepare this dish:
   - Highlight oil reuse and lipid degradation (Total Polar Compounds).
   - Point out high refined carb and sodium density versus low micronutrient/fiber density.
   - Explain what cooking phases (e.g., high-heat wok frying, deep-frying, steaming) do to the ingredients.
4. Assign appropriate safety categories to each constituent component.
"""
6. End-to-End Service Implementation (app/services/gemini_service.py)
Antigravity must use this exact implementation pattern incorporating error checking and exponential backoff[cite: 2]:

Python
import asyncio
from google import genai
from google.genai import types
from google.genai.errors import APIError
from app.schemas.analysis import FoodAnalysisSchema
from app.core.config import settings

class GeminiAnalysisService:
    def __init__(self):
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        self.model_name = "gemini-2.5-flash"

    async def generate_structured_analysis(
        self, 
        contents: list, 
        max_retries: int = 3
    ) -> FoodAnalysisSchema:
        """Executes Gemini 2.5 Flash request with strict JSON schema enforcement and backoff."""
        delay = 2.0
        
        config = types.GenerateContentConfig(
            system_instruction=settings.SYSTEM_INSTRUCTION,
            response_mime_type="application/json",
            response_schema=FoodAnalysisSchema,
            temperature=0.2,
            max_output_tokens=2048,
        )

        for attempt in range(max_retries):
            try:
                response = self.client.models.generate_content(
                    model=self.model_name,
                    contents=contents,
                    config=config
                )
                
                # Parse strict JSON directly into Pydantic model
                return FoodAnalysisSchema.model_validate_json(response.text)

            except APIError as e:
                # 429: Resource Exhausted (Rate Limit) -> Exponential Backoff
                if e.code == 429 and attempt < max_retries - 1:
                    await asyncio.sleep(delay)
                    delay *= 2
                    continue
                raise RuntimeError(f"Gemini API Error [{e.code}]: {e.message}")
            except Exception as ex:
                if attempt < max_retries - 1:
                    await asyncio.sleep(delay)
                    delay *= 2
                    continue
                raise RuntimeError(f"Failed to generate analysis: {str(ex)}")

        raise RuntimeError("Exceeded maximum retry attempts on Gemini API.")

gemini_service = GeminiAnalysisService()
