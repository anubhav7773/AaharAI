"""Integration smoke test for the live Open Food Facts API."""

import asyncio
from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.services.off_service import off_service


async def test_off_integration() -> None:
    print("Testing Open Food Facts Service...")

    barcode = "3017624010701"
    print(f"\n1. Fetching valid barcode: {barcode}")
    result = await off_service.fetch_product_by_barcode(barcode)
    assert result is not None, "Failed to fetch known barcode!"
    assert result["food_name"], "Missing food_name in parsed output"
    assert result["nutrients"]["calories"] > 0, "Calories extraction failed"
    print("   Food Name:", result["food_name"])
    print("   Calories (per 100g):", result["nutrients"]["calories"])
    print("   Allergens Found:", result["allergens"])
    print("   Raw Ingredients Sample:", (result["ingredients_raw"] or "")[:60], "...")

    invalid_barcode = "0000000000000"
    print(f"\n2. Fetching non-existent barcode: {invalid_barcode}")
    invalid_result = await off_service.fetch_product_by_barcode(invalid_barcode)
    assert invalid_result is None, "Invalid barcode should return None!"
    print("   Handled non-existent barcode properly (returned None)")

    print("\nSub-Phase 2.1 SUCCESS: Open Food Facts Client is fully operational!")


if __name__ == "__main__":
    asyncio.run(test_off_integration())
