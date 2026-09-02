# Doc 06: Open Food Facts (OFF) API Integration & Cache Pipeline

## 1. Architectural Role & Boundary
- **Core Function**: AaharAi ke barcode lookup pipeline ka first-line external data provider.
- **Cost Impact**: 100% Free, open-source crowdsourced database[cite: 1]. Barcode lookup direct Gemini vision call karne se pehle OFF par run hota hai, jisse AI token quota aur processing latency drastically reduce ho jati hai[cite: 1, 2].
- **Production Target Endpoint**: `https://world.openfoodfacts.org/api/v2/product/{barcode}`
- **Staging Testing Endpoint**: `https://world.openfoodfacts.net/api/v2/product/{barcode}`
  - *Staging Credentials*: HTTP Basic Auth (`Username: off`, `Password: off`)

---

## 2. Mandatory Rules & Compliance Protocols

Antigravity ko OFF integration mein niche diye gaye teen strict legal aur operational rules follow karne honge:

### 2.1 Mandatory User-Agent Header Standard
OFF API automated bots aur nameless traffic ko block ya ban karti hai. Har HTTP request ke saath explicit, identifiable header bhejna statutory requirement hai[cite: 2]:
- **Header Key**: `User-Agent`[cite: 2]
- **Format**: `<AppName>/<AppVersion> (<ContactEmail>)`[cite: 2]
- **Production Constant**:
  ```python
  OFF_HEADERS = {
      "User-Agent": "AaharAi/1.0 (founder@asiverticals.me)"
  }
2.2 Strict Rate Limiting (15 Requests / Minute)
Policy: OFF read API single IP address ke liye 15 requests per minute allow karti hai[cite: 2].

Server Limit Handling: Peak traffic par OFF server HTTP 503 (Service Unavailable) return kar sakta hai[cite: 2].

Backend Throttling Defense:

FastAPI layer par per-IP local sliding-window rate limiter enforce karna hai taaki traffic 15 req/min ke andar rahe[cite: 2].

Duplicate scans ke liye pehle Supabase food_cache check karna mandatory hai[cite: 1].

2.3 Payload Optimization via Query Projections
Full product JSON download karne ke bajaye payload speed aur memory usage optimize karne ke liye URL mein strictly fields query parameter specify karna hai[cite: 2]:

?fields=product_name,brands,ingredients_text,nutriments
3. Request URL & Response Payload Contract
3.1 Live GET Request Structure
HTTP
GET [https://world.openfoodfacts.org/api/v2/product/3017624010701?fields=product_name,brands,ingredients_text,nutriments](https://world.openfoodfacts.org/api/v2/product/3017624010701?fields=product_name,brands,ingredients_text,nutriments) HTTP/1.1
Host: world.openfoodfacts.org
User-Agent: AaharAi/1.0 (founder@asiverticals.me)
Accept: application/json
3.2 Expected OFF JSON Payload (Nutella Example: 3017624010701)
JSON
{
  "code": "3017624010701",
  "status": 1,
  "status_verbose": "product found",
  "product": {
    "product_name": "Nutella",
    "brands": "Ferrero",
    "ingredients_text": "Sugar, palm oil, hazelnuts (13%), skimmed milk powder (8.7%), fat-reduced cocoa (7.4%), emulsifier: lecithins (soya), vanillin.",
    "nutriments": {
      "energy-kcal": 539,
      "energy-kcal_100g": 539,
      "energy-kcal_unit": "kcal",
      "sugars": 56.3,
      "sugars_100g": 56.3,
      "sugars_unit": "g",
      "fat": 30.9,
      "fat_100g": 30.9,
      "fat_unit": "g",
      "proteins": 6.3,
      "proteins_100g": 6.3,
      "salt": 0.107,
      "salt_100g": 0.107
    }
  }
}
3.3 Product Not Found Response (status: 0)
JSON
{
  "code": "8901234567890",
  "status": 0,
  "status_verbose": "product not found"
}
4. End-to-End Client Service (app/services/off_service.py)
Antigravity must generate this exact asynchronous service class inside the FastAPI engine[cite: 2]:

Python
import httpx
from typing import Optional, Dict, Any
from pydantic import BaseModel

class OFFProductData(BaseModel):
    barcode: str
    product_name: str
    brand_name: Optional[str] = None
    ingredients_text: str
    calories_100g: float = 0.0
    protein_100g: float = 0.0
    carbs_100g: float = 0.0
    fat_100g: float = 0.0
    fiber_100g: float = 0.0
    is_found: bool

class OpenFoodFactsClient:
    BASE_URL = "[https://world.openfoodfacts.org/api/v2/product](https://world.openfoodfacts.org/api/v2/product)"
    HEADERS = {
        "User-Agent": "AaharAi/1.0 (founder@asiverticals.me)",
        "Accept": "application/json"
    }
    TIMEOUT_SECONDS = 5.0

    async def fetch_product_by_barcode(self, barcode: str) -> Optional[OFFProductData]:
        """
        Queries Open Food Facts API v2 with field projection.
        Returns normalized OFFProductData or None if status != 1.
        """
        fields = "product_name,brands,ingredients_text,nutriments"
        url = f"{self.BASE_URL}/{barcode}?fields={fields}"

        async with httpx.AsyncClient(timeout=self.TIMEOUT_SECONDS) as client:
            try:
                response = await client.get(url, headers=self.HEADERS)
                
                # Check for rate limiting or server errors
                if response.status_code == 503:
                    # OFF overloaded, gracefully trigger fallback
                    return None
                
                response.raise_for_status()
                data: Dict[str, Any] = response.json()
            except (httpx.HTTPError, ValueError):
                return None

        # Validate product existence flag
        if data.get("status") != 1 or "product" not in data:
            return None

        product = data["product"]
        nutriments = product.get("nutriments", {})

        # Safe parsing of nutrients (handling string or float numbers)
        def _extract_nutrient(key_100g: str, fallback_key: str) -> float:
            val = nutriments.get(key_100g)
            if val is None:
                val = nutriments.get(fallback_key, 0.0)
            try:
                return float(val)
            except (ValueError, TypeError):
                return 0.0

        return OFFProductData(
            barcode=barcode,
            product_name=product.get("product_name") or "Packaged Product",
            brand_name=product.get("brands"),
            ingredients_text=product.get("ingredients_text") or "",
            calories_100g=_extract_nutrient("energy-kcal_100g", "energy-kcal"),
            protein_100g=_extract_nutrient("proteins_100g", "proteins"),
            carbs_100g=_extract_nutrient("carbohydrates_100g", "carbohydrates"),
            fat_100g=_extract_nutrient("fat_100g", "fat"),
            fiber_100g=_extract_nutrient("fiber_100g", "fiber"),
            is_found=True
        )

off_client = OpenFoodFactsClient()
5. Decision Flow & Fallback Architecture
                       [ Barcode Scanned ]
                                |
                                v
               [ Query Supabase `food_cache` ]
                     /                   \
           (HIT)    /                     \ (MISS)
                   v                       v
          [ Return 200 OK ]         [ Query OFF API v2 ]
                                     /              \
                           (status: 1)              (status: 0 or HTTP 503)
                                 /                      \
                                v                        v
                     [ Send raw ingredients        [ Return HTTP 404 ]
                       to Gemini 2.5 Flash ]             |
                                |                        v
                                v               [ Flutter Client triggers:
                     [ Store in `food_cache` ]   "Barcode not found. Snap a photo
                                |                of the ingredient list." ]
                                v
                        [ Return 200 OK ]
6. Testing & Validation Commands
Antigravity can test the integrity of the OFF integration directly in terminal using these exact requests:

1. Test Valid Barcode (Nutella EAN-13)
Bash
curl -X GET "[https://world.openfoodfacts.org/api/v2/product/3017624010701?fields=product_name,ingredients_text,nutriments](https://world.openfoodfacts.org/api/v2/product/3017624010701?fields=product_name,ingredients_text,nutriments)" \
     -H "User-Agent: AaharAi/1.0 (founder@asiverticals.me)"
2. Test Invalid / Unregistered Barcode (Triggers Fallback)
Bash
curl -X GET "[https://world.openfoodfacts.org/api/v2/product/0000000000000?fields=product_name,ingredients_text,nutriments](https://world.openfoodfacts.org/api/v2/product/0000000000000?fields=product_name,ingredients_text,nutriments)" \
     -H "User-Agent: AaharAi/1.0 (founder@asiverticals.me)"
3. Verify Local FastAPI Barcode Endpoint
Bash
curl -X GET "[http://127.0.0.1:8000/api/v1/scan/barcode/3017624010701](http://127.0.0.1:8000/api/v1/scan/barcode/3017624010701)"