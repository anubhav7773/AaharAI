"""Live Supabase cache lifecycle smoke test."""

import asyncio
from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.services.cache_service import cache_service


async def test_cache_lifecycle() -> None:
    print("Testing Supabase Food Cache Read-Through / Write-Through Layer...")
    test_barcode = "8901234567890"
    payload = {
        "barcode": test_barcode,
        "food_name": "Test Baked Multigrain Rusk",
        "brand_name": "AaharAi Test Kitchen",
        "source": "open_food_facts",
        "ingredients_raw": "Whole Wheat Flour, Sugar, Yeast, Cardamom",
        "parsed_ingredients": [],
        "nutrients": {"calories": 410.0, "protein_g": 9.5},
        "allergens": ["Gluten"],
    }

    print(f"\n1. Writing test food (barcode: {test_barcode})...")
    saved = await cache_service.save_to_cache(payload)
    assert saved["food_name"] == payload["food_name"]

    print("\n2. Reading the cache entry and incrementing hit_count...")
    hit = await cache_service.get_by_barcode(test_barcode)
    assert hit is not None
    assert hit["food_name"] == payload["food_name"]
    print("   Cache Hit Verified:", hit["food_name"])
    print("   Hit Count:", hit.get("hit_count"))

    signature = cache_service.generate_signature_hash(
        "Sugar, PALM OIL, Hazelnuts (13%)  "
    )
    assert len(signature) == 64
    print("\n3. Signature Hash Verified:", f"{signature[:16]}...")
    print("\nSub-Phase 2.3 SUCCESS: Supabase Deduplication Engine is operational!")


if __name__ == "__main__":
    asyncio.run(test_cache_lifecycle())
