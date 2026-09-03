from unittest.mock import AsyncMock, patch
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.food import (
    GeminiFoodExtractionSchema,
    NutrientProfileSchema,
    ParsedIngredientSchema,
    IngredientSafetyEnum,
)
from app.services.gemini_service import GeminiInferenceService


@pytest.fixture
def client():
    return TestClient(app)


def test_health_endpoints(client: TestClient):
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"

    resp_uptime = client.get("/uptime")
    assert resp_uptime.status_code == 200

    head_resp = client.head("/health")
    assert head_resp.status_code == 200


def test_gemini_clean_json_text():
    raw_markdown = """```json
    {
        "food_name": "Samosa",
        "nutrients": {"calories": 250, "protein_g": 4, "carbs_g": 30, "fat_g": 12},
        "parsed_ingredients": [],
        "allergens": []
    }
    ```"""
    cleaned = GeminiInferenceService._clean_json_text(raw_markdown)
    assert not cleaned.startswith("```")
    assert not cleaned.endswith("```")
    assert '"food_name": "Samosa"' in cleaned


def test_health_claim_middleware_does_not_mutate_error_responses(client: TestClient):
    with patch(
        "app.api.v1.endpoints.scan.cache_service.get_by_barcode",
        new_callable=AsyncMock,
        return_value=None,
    ), patch(
        "app.api.v1.endpoints.scan.off_service.fetch_product_by_barcode",
        new_callable=AsyncMock,
        return_value=None,
    ):
        resp = client.get("/api/v1/scan/barcode/0000000000000")
        assert resp.status_code == 404
        data = resp.json()
        assert "detail" in data
        # Crucial reliability assertion: health_disclaimer should NOT be injected into 404 error responses
        assert "health_disclaimer" not in data


def test_scan_barcode_cached_hit(client: TestClient):
    cached_payload = {
        "id": "item-123",
        "barcode": "8901234567890",
        "food_name": "Masala Oats",
        "brand_name": "Saffola",
        "source": "open_food_facts",
        "nutrients": {"calories": 380, "protein_g": 10, "carbs_g": 65, "fat_g": 8},
        "parsed_ingredients": [
            {
                "name": "Rolled Oats",
                "safety": "safe",
                "plain_explanation": "Whole grain rolled oats",
            }
        ],
        "allergens": ["Gluten/Wheat"],
    }
    with patch(
        "app.api.v1.endpoints.scan.cache_service.get_by_barcode",
        new_callable=AsyncMock,
        return_value=cached_payload,
    ):
        resp = client.get("/api/v1/scan/barcode/8901234567890")
        assert resp.status_code == 200
        data = resp.json()
        assert data["food_name"] == "Masala Oats"
        assert data["health_disclaimer"] is not None


def test_street_food_inference_endpoint(client: TestClient):
    fake_extracted = GeminiFoodExtractionSchema(
        food_name="Chole Bhature",
        serving_size="2 bhature with chole",
        nutrients=NutrientProfileSchema(
            calories=550.0,
            protein_g=14.0,
            carbs_g=72.0,
            fat_g=22.0,
        ),
        parsed_ingredients=[
            ParsedIngredientSchema(
                name="Chickpeas",
                safety=IngredientSafetyEnum.safe,
                plain_explanation="Boiled garbanzo beans in Indian spices",
            )
        ],
        allergens=["Gluten/Wheat"],
        preparation_insights="Fried in oil.",
    )

    with patch(
        "app.api.v1.endpoints.scan.cache_service.search_street_food",
        new_callable=AsyncMock,
        return_value=[],
    ), patch(
        "app.api.v1.endpoints.scan.gemini_service.estimate_street_food",
        new_callable=AsyncMock,
        return_value=fake_extracted,
    ), patch(
        "app.api.v1.endpoints.scan.cache_service.save_to_cache",
        new_callable=AsyncMock,
        side_effect=lambda item: item,
    ):
        resp = client.get("/api/v1/scan/street-food?dish_name=Chole%20Bhature")
        assert resp.status_code == 200
        data = resp.json()
        assert data["food_name"] == "Chole Bhature"
        assert data["nutrients"]["calories"] == 550.0
        assert data["source"] == "street_food"
