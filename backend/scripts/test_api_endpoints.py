"""ASGI integration smoke tests for the public API routes."""

import asyncio
from pathlib import Path
import sys
from unittest.mock import AsyncMock, patch

from httpx import ASGITransport, AsyncClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.main import app
from app.schemas.food import (
    GeminiFoodExtractionSchema,
    NutrientProfileSchema,
)


def extraction(source_name: str) -> GeminiFoodExtractionSchema:
    return GeminiFoodExtractionSchema(
        food_name=source_name,
        nutrients=NutrientProfileSchema(calories=250),
        preparation_insights="Example preparation note",
    )


async def test_api_suite() -> None:
    with (
        patch(
            "app.api.v1.endpoints.scan.cache_service.get_by_barcode",
            new=AsyncMock(return_value=None),
        ),
        patch(
            "app.api.v1.endpoints.scan.off_service.fetch_product_by_barcode",
            new=AsyncMock(
                return_value={
                    "food_name": "Test Food",
                    "nutrients": {"calories": 100},
                    "ingredients_raw": None,
                }
            ),
        ),
        patch(
            "app.api.v1.endpoints.scan.cache_service.save_to_cache",
            new=AsyncMock(
                side_effect=lambda data: {**data, "id": "test-id"}
            ),
        ),
        patch(
            "app.api.v1.endpoints.scan.cache_service.search_street_food",
            new=AsyncMock(return_value=[]),
        ),
        patch(
            "app.api.v1.endpoints.scan.gemini_service.estimate_street_food",
            new=AsyncMock(return_value=extraction("Veg Steamed Momo")),
        ),
    ):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            health = await client.get("/health")
            assert health.status_code == 200
            assert health.json()["status"] == "healthy"

            uptime = await client.get("/uptime")
            assert uptime.status_code == 200
            assert uptime.json()["status"] == "healthy"

            barcode = await client.get("/api/v1/scan/barcode/3017624010701")
            assert barcode.status_code == 200
            assert barcode.json()["food_name"] == "Test Food"

            street = await client.get(
                "/api/v1/scan/street-food?dish_name=Veg+Steamed+Momo"
            )
            assert street.status_code == 200
            assert street.json()["source"] == "street_food"

    print("Sub-Phase 2.4 SUCCESS: API endpoints are verified and functional!")


if __name__ == "__main__":
    asyncio.run(test_api_suite())
