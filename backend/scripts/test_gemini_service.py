"""Live Gemini structured-inference smoke test."""

import asyncio
from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.services.gemini_service import gemini_service


async def test_gemini() -> None:
    print("Testing Gemini 2.5 Flash Structured Inference Service...")
    result = await gemini_service.parse_ingredients_text(
        food_name="Hazelnut Cocoa Spread",
        raw_ingredients=(
            "Sugar, Palm Oil, Hazelnuts (13%), Skimmed Milk Powder (8.7%), "
            "Fat-Reduced Cocoa (7.4%), Emulsifier: Lecithins (Soya) (INS 322), Vanillin."
        ),
    )
    assert result.food_name
    assert len(result.parsed_ingredients) >= 4
    print("   Extracted Food:", result.food_name)
    print("   Molecules:", len(result.parsed_ingredients))
    print("   Allergens:", result.allergens)

    street_result = await gemini_service.estimate_street_food("Veg Steamed Momo")
    assert street_result.nutrients.calories > 0
    assert street_result.preparation_insights
    print("   Estimated Calories:", street_result.nutrients.calories)
    print("   Preparation Insights:", street_result.preparation_insights[:80])
    print("\nSub-Phase 2.2 SUCCESS: Gemini structured engine is operational!")


if __name__ == "__main__":
    asyncio.run(test_gemini())
