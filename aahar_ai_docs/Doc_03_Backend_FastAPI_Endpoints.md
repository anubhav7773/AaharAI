# Doc 03: FastAPI Backend Endpoints & Async Engine

## 1. Architectural Principles & Free-Tier Operational Bounds
- **Framework**: FastAPI (Python 3.11+) asynchronous REST service.
- **Deployment**: Render Free Web Service (Spins down after 15 minutes of inactivity)[cite: 1].
- **Cold-Start Elimination**: The Flutter client fires a non-blocking `GET /health` call upon opening the camera viewfinder to wake up the server instance in advance.
- **Quota Safeguards**:
  - **Open Food Facts (OFF)**: Strict 15 requests/minute throttle cap, identified by custom `User-Agent`.
  - **Gemini Free Tier**: Strict exponential backoff retry interceptor for handling `HTTP 429 RESOURCE_EXHAUSTED` codes.
  - **Deduplication**: Read-through/Write-through Supabase `food_cache` layer prevents redundant AI invocations[cite: 1].
- **Transient Memory Policy**: Vision images uploaded via multipart requests are held purely in RAM buffers (`io.BytesIO`), fed directly to Gemini 2.5 Flash, and discarded immediately after parsing. Never save images to disk or Supabase buckets[cite: 1].

---

## 2. Pydantic v2 Strict Data Contracts (`app/schemas/analysis.py`)

Antigravity must use these exact Pydantic definitions. Any field mismatch will break the client-side deserialization.

```python
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Literal

class IngredientItem(BaseModel):
    name: str = Field(
        ..., 
        description="Standard name or INS identification code of the ingredient (e.g., 'INS 102 (Tartrazine)')"
    )
    simple_explanation: str = Field(
        ..., 
        description="One simple, plain conversational sentence explaining what this does in daily food"
    )
    category: Literal["safe", "moderate", "avoid"] = Field(
        ..., 
        description="Evaluation safety bucket based on FSSAI safety norms"
    )
    health_note: str = Field(
        ..., 
        description="Clear regulatory or wellness context (e.g., ADI limit, purity threshold, or common consumer advisory)"
    )

class NutrientProfile(BaseModel):
    calories_100g: float = Field(0.0, description="Energy in kcal per 100g edible portion")
    protein_100g: float = Field(0.0, description="Total protein in grams per 100g")
    carbs_100g: float = Field(0.0, description="Total carbohydrates in grams per 100g")
    fat_100g: float = Field(0.0, description="Total fat content in grams per 100g")
    fiber_100g: float = Field(0.0, description="Total dietary fiber in grams per 100g")

    @field_validator("calories_100g", "protein_100g", "carbs_100g", "fat_100g", "fiber_100g", mode="before")
    def sanitize_null_nutrients(cls, v):
        if v is None:
            return 0.0
        return float(v)

class FoodAnalysisResponse(BaseModel):
    food_name: str = Field(..., description="Recognized product name or traditional dish title")
    brand_name: Optional[str] = Field(None, description="Commercial brand name if identified")
    source: Literal["open_food_facts", "gemini_vision", "street_food"] = Field(..., description="Pipeline source")
    nutrients: NutrientProfile = Field(..., description="Standard nutritional facts per 100g")
    allergens_detected: List[str] = Field(
        default_factory=list, 
        description="FSSAI standard allergens present: Milk, Gluten, Soy, Nuts, Fish, Egg, Crustacean, Sulphite"
    )
    ingredients: List[IngredientItem] = Field(
        default_factory=list, 
        description="List of deconstructed ingredients and additive molecules"
    )
    preparation_insights: Optional[str] = Field(
        None, 
        description="Critical hidden preparation steps for street foods (e.g. repeated frying oil reuse, high refined starch)"
    )

class BarcodeLookupRequest(BaseModel):
    barcode: str = Field(..., regex=r"^\d{8,14}$", description="Valid EAN-8, EAN-13, or UPC-A barcode")
3. Core Engine Implementation (app/main.py)Pythonimport os
import io
import hashlib
import asyncio
from typing import Optional
import httpx
from fastapi import FastAPI, HTTPException, UploadFile, File, Path, status
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from google.genai.errors import APIError

from app.schemas.analysis import FoodAnalysisResponse, IngredientItem, NutrientProfile

app = FastAPI(
    title="AaharAi Engine",
    version="1.0.0",
    description="Zero-budget production AI food transparency backend"
)

# Cross-Origin Isolation Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict to mobile client domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Configuration & Clients
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

gemini_client = genai.Client(api_key=GEMINI_API_KEY) if GEMINI_API_KEY else None

OFF_API_BASE = "[https://world.openfoodfacts.org/api/v2/product](https://world.openfoodfacts.org/api/v2/product)"
OFF_HEADERS = {"User-Agent": "AaharAi/1.0 (founder@asiverticals.me)"}

SYSTEM_INSTRUCTION = """
You are an expert Indian food science and nutrition analyst for AaharAi.
Rules:
1. Explain ingredients in 100% plain, conversational language for an everyday consumer.
2. Adhere strictly to FSSAI labelling rules: Recognize INS additive numbers and identify mandatory allergens (Milk, Gluten, Soy, Nuts, Fish, Egg, Crustacean, Sulphite).
3. If analyzing Indian street/unpacked foods, estimate base nutrients using Indian Food Composition Tables (IFCT 2017) baselines. Highlight hidden preparation phases (e.g. reused frying oil, excessive salt, refined flour).
4. Strictly educational and neutral. Never diagnose medical conditions, never use words like 'cure', 'disease reversal', or 'prescribe'.
"""

# ============================================================================
# HELPER: Supabase Cache Interactions
# ============================================================================
async def query_supabase_cache(barcode: Optional[str] = None, signature_hash: Optional[str] = None) -> Optional[dict]:
    """Checks the shared food_cache table to save Gemini tokens and stay within free tier."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        return None

    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    }
    
    query_param = f"barcode=eq.{barcode}" if barcode else f"signature_hash=eq.{signature_hash}"
    url = f"{SUPABASE_URL}/rest/v1/food_cache?{query_param}&select=*"

    async with httpx.AsyncClient(timeout=4.0) as client:
        try:
            res = await client.get(url, headers=headers)
            if res.status_code == 200:
                rows = res.json()
                if rows:
                    # Increment hit counter asynchronously (fire and forget)
                    cache_id = rows[0]["id"]
                    new_hit = rows[0].get("hit_count", 1) + 1
                    asyncio.create_task(client.patch(
                        f"{SUPABASE_URL}/rest/v1/food_cache?id=eq.{cache_id}",
                        headers=headers,
                        json={"hit_count": new_hit}
                    ))
                    return rows[0]
        except Exception:
            return None
    return None

async def store_supabase_cache(payload: dict) -> None:
    """Saves structured analysis back to Supabase food_cache."""
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        return

    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Prefer": "resolution=merge-duplicates"
    }
    url = f"{SUPABASE_URL}/rest/v1/food_cache"

    async with httpx.AsyncClient(timeout=4.0) as client:
        try:
            await client.post(url, headers=headers, json=payload)
        except Exception:
            pass

# ============================================================================
# HELPER: Gemini Exponential Backoff Wrapper
# ============================================================================
async def call_gemini_with_retry(contents: list, max_retries: int = 3) -> str:
    """Executes Gemini 2.5 Flash calls with exponential backoff for HTTP 429 mitigation."""
    delay = 1.5
    for attempt in range(max_retries):
        try:
            response = gemini_client.models.generate_content(
                model="gemini-2.5-flash",
                contents=contents,
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_INSTRUCTION,
                    response_mime_type="application/json",
                    response_schema=FoodAnalysisResponse,
                    temperature=0.2
                )
            )
            return response.text
        except APIError as e:
            if e.code == 429 and attempt < max_retries - 1:
                await asyncio.sleep(delay)
                delay *= 2
            else:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="AI Engine is temporarily overloaded. Please retry in a moment."
                )
        except Exception as ex:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"AI generation failed: {str(ex)}"
            )
    raise HTTPException(status_code=status.HTTP_504_GATEWAY_TIMEOUT, detail="Request timeout on AI model.")

# ============================================================================
# ENDPOINTS
# ============================================================================

@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """Warms up the Render instance when the user opens the camera screen."""
    return {"status": "online", "service": "AaharAi Backend", "budget": "free_tier"}


@app.get("/api/v1/scan/barcode/{barcode}", response_model=FoodAnalysisResponse)
async def scan_by_barcode(barcode: str = Path(..., description="Product barcode (EAN-8, EAN-13, UPC)")):
    """
    Barcode Pipeline:
    1. Check Supabase food_cache -> return immediately if hit.
    2. Query Open Food Facts API.
    3. If OFF missing -> HTTP 404 (Triggers image scan prompt in Flutter).
    4. If OFF found -> Send ingredients to Gemini to translate into plain language.
    5. Cache in Supabase and return.
    """
    # 1. Supabase Cache Check
    cached = await query_supabase_cache(barcode=barcode)
    if cached:
        return FoodAnalysisResponse(
            food_name=cached["food_name"],
            brand_name=cached.get("brand_name"),
            source="open_food_facts",
            nutrients=NutrientProfile(**cached["nutrients"]),
            allergens_detected=cached.get("allergens", []),
            ingredients=[IngredientItem(**item) for item in cached.get("parsed_ingredients", [])],
            preparation_insights=cached.get("preparation_insights")
        )

    # 2. Query Open Food Facts
    fields = "product_name,brands,ingredients_text,nutriments"
    url = f"{OFF_API_BASE}/{barcode}?fields={fields}"
    
    async with httpx.AsyncClient(timeout=5.0) as client:
        try:
            res = await client.get(url, headers=OFF_HEADERS)
            data = res.json()
        except Exception as err:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"OFF Gateway failed: {str(err)}")

    # 3. Handle Product Not Found
    if data.get("status") != 1 or "product" not in data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Barcode not found in database. Trigger image OCR."
        )

    product = data["product"]
    product_name = product.get("product_name") or "Packaged Snack"
    brand_name = product.get("brands")
    raw_ingredients = product.get("ingredients_text") or ""
    nutriments = product.get("nutriments", {})

    cals = nutriments.get("energy-kcal_100g") or nutriments.get("energy-kcal", 0.0)
    protein = nutriments.get("proteins_100g") or nutriments.get("proteins", 0.0)
    carbs = nutriments.get("carbohydrates_100g") or nutriments.get("carbohydrates", 0.0)
    fat = nutriments.get("fat_100g") or nutriments.get("fat", 0.0)
    fiber = nutriments.get("fiber_100g") or nutriments.get("fiber", 0.0)

    # 4. Gemini Translation
    prompt = f"""
    Analyze this packaged Indian food item:
    Product: {product_name}
    Brand: {brand_name or 'N/A'}
    Raw Ingredient Label: {raw_ingredients}
    Baseline Nutrients (per 100g): Calories: {cals}, Protein: {protein}g, Carbs: {carbs}g, Fat: {fat}g, Fiber: {fiber}g

    Parse each ingredient and INS code into simple everyday terms. Identify FSSAI mandatory allergens.
    """

    json_str = await call_gemini_with_retry(contents=[prompt])
    result = FoodAnalysisResponse.model_validate_json(json_str)

    # Override nutrients with authoritative OFF data if Gemini zeroed them
    if result.nutrients.calories_100g == 0.0 and float(cals) > 0:
        result.nutrients = NutrientProfile(
            calories_100g=float(cals),
            protein_100g=float(protein),
            carbs_100g=float(carbs),
            fat_100g=float(fat),
            fiber_100g=float(fiber)
        )

    # 5. Asynchronous Cache Storage
    cache_payload = {
        "barcode": barcode,
        "food_name": result.food_name,
        "brand_name": result.brand_name,
        "source": "open_food_facts",
        "ingredients_raw": raw_ingredients,
        "parsed_ingredients": [item.model_dump() for item in result.ingredients],
        "nutrients": result.nutrients.model_dump(),
        "allergens": result.allergens_detected,
        "preparation_insights": result.preparation_insights
    }
    asyncio.create_task(store_supabase_cache(cache_payload))

    return result


@app.post("/api/v1/scan/vision", response_model=FoodAnalysisResponse)
async def scan_by_vision(file: UploadFile = File(...)):
    """
    Multimodal Vision Pipeline:
    1. Reads image into memory buffer (no disk write).
    2. Hashes image bytes for deduplication.
    3. Calls Gemini 2.5 Flash multimodal endpoint to OCR and analyze in a single shot.
    4. Caches structured JSON into Supabase and returns.
    """
    if file.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid format. Only JPEG, PNG, and WebP are accepted.")

    image_bytes = await file.read()
    if len(image_bytes) > 15 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File too large. Maximum size is 15MB.")

    # Deduplication Hash
    sig_hash = hashlib.sha256(image_bytes).hexdigest()
    cached = await query_supabase_cache(signature_hash=sig_hash)
    if cached:
        return FoodAnalysisResponse(
            food_name=cached["food_name"],
            brand_name=cached.get("brand_name"),
            source="gemini_vision",
            nutrients=NutrientProfile(**cached["nutrients"]),
            allergens_detected=cached.get("allergens", []),
            ingredients=[IngredientItem(**item) for item in cached.get("parsed_ingredients", [])],
            preparation_insights=cached.get("preparation_insights")
        )

    prompt = (
        "Read the ingredient label and nutritional table from this photo. "
        "Deconstruct all chemical additives (INS numbers), detect allergens, "
        "and explain every ingredient in everyday simple language."
    )

    contents = [
        types.Part.from_bytes(data=image_bytes, mime_type=file.content_type),
        prompt
    ]

    json_str = await call_gemini_with_retry(contents=contents)
    result = FoodAnalysisResponse.model_validate_json(json_str)
    result.source = "gemini_vision"

    # Cache payload
    cache_payload = {
        "signature_hash": sig_hash,
        "food_name": result.food_name,
        "brand_name": result.brand_name,
        "source": "gemini_vision",
        "parsed_ingredients": [item.model_dump() for item in result.ingredients],
        "nutrients": result.nutrients.model_dump(),
        "allergens": result.allergens_detected,
        "preparation_insights": result.preparation_insights
    }
    asyncio.create_task(store_supabase_cache(cache_payload))

    return result


@app.get("/api/v1/scan/street-food", response_model=FoodAnalysisResponse)
async def scan_street_food(dish_name: str):
    """
    Unpacked Street Food Pipeline:
    Estimates nutritional profile using IFCT 2017 baselines and highlights
    hidden processing phases (e.g. reused frying oil, refined flour density).
    """
    prompt = f"""
    Deconstruct Indian street food dish: '{dish_name}'.
    1. Estimate baseline nutrients per 100g portion using Indian Food Composition Tables (IFCT 2017) averages.
    2. Detail typical raw ingredients (e.g. refined flour/maida, trans fats, vegetables, MSG/salt).
    3. In 'preparation_insights', transparently explain typical commercial prep phases (oil reuse, excessive sodium, frying temperature).
    4. Categorize each ingredient simply into safe, moderate, or avoid.
    """

    json_str = await call_gemini_with_retry(contents=[prompt])
    result = FoodAnalysisResponse.model_validate_json(json_str)
    result.source = "street_food"

    return result
4. Error Handling & Status Code StandardsStatus CodeTrigger ConditionMobile Client Action200 OKSuccessful parsing from Cache, OFF, or Gemini.  Render analysis UI directly.  404 NOT_FOUNDBarcode does not exist in Open Food Facts.  Automatically prompt the user to snap a photo of the back-label[cite: 1, 2].413 TOO_LARGEUploaded image exceeds 15 MB boundary.Compress image locally before re-transmitting.  429 TOO_MANY_REQUESTSRate limit hit on external APIs[cite: 2].Exponential backoff triggers internally; displays non-blocking toast[cite: 2].502 BAD_GATEWAYOFF or Supabase upstream network connection failure[cite: 2].Prompt user: "Food database unreachable. Try photo scan."[cite: 2]