"""Open Food Facts API client and response normalizer."""

from typing import Any, Dict, Optional

import httpx

from app.core.config import settings


class OpenFoodFactsService:
    """Fetch and normalize the small OFF product payload needed by AaharAi."""

    def __init__(self) -> None:
        self.base_url = settings.OFF_BASE_URL.rstrip("/")
        self.headers = {
            "User-Agent": settings.OFF_USER_AGENT,
            "Accept": "application/json",
        }
        self.timeout = httpx.Timeout(settings.OFF_TIMEOUT_SECONDS)
        self.requested_fields = (
            "code,product_name,brands,ingredients_text,nutriments,"
            "allergens_tags,serving_size"
        )

    async def fetch_product_by_barcode(
        self, barcode: str
    ) -> Optional[Dict[str, Any]]:
        """Return normalized product data, or None when OFF cannot provide it."""
        clean_barcode = barcode.strip()
        if not clean_barcode:
            return None

        url = f"{self.base_url}/{clean_barcode}.json"
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    url,
                    headers=self.headers,
                    params={"fields": self.requested_fields},
                )
                if response.status_code != 200:
                    return None

                data = response.json()
                if data.get("status") in (0, "0") or "product" not in data:
                    return None
                product = data["product"]
                if not isinstance(product, dict):
                    return None
                return self._normalize_off_data(clean_barcode, product)
        except (httpx.TimeoutException, httpx.RequestError, ValueError):
            return None

    def _normalize_off_data(
        self, barcode: str, product: Dict[str, Any]
    ) -> Dict[str, Any]:
        nutriments = product.get("nutriments")
        if not isinstance(nutriments, dict):
            nutriments = {}

        calories = self._as_float(
            nutriments.get("energy-kcal_100g", nutriments.get("energy-kcal"))
        )
        sodium = self._as_float(nutriments.get("sodium_100g"))
        raw_allergens = product.get("allergens_tags")
        allergens = (
            self._normalize_allergen(tag)
            for tag in raw_allergens
            if isinstance(tag, str)
        ) if isinstance(raw_allergens, list) else []

        return {
            "barcode": barcode,
            "food_name": product.get("product_name") or "Unknown Packaged Item",
            "brand_name": product.get("brands"),
            "source": "open_food_facts",
            "serving_size": product.get("serving_size"),
            "ingredients_raw": product.get("ingredients_text"),
            "allergens": list(allergens),
            "nutrients": {
                "calories": calories,
                "protein_g": self._as_float(nutriments.get("proteins_100g"), 0.0),
                "carbs_g": self._as_float(
                    nutriments.get("carbohydrates_100g"), 0.0
                ),
                "fat_g": self._as_float(nutriments.get("fat_100g"), 0.0),
                "saturated_fat_g": self._optional_float(
                    nutriments.get("saturated-fat_100g")
                ),
                "added_sugar_g": self._optional_float(nutriments.get("sugars_100g")),
                "sodium_mg": sodium * 1000 if sodium is not None else None,
                "fiber_g": self._optional_float(nutriments.get("fiber_100g")),
            },
        }

    @staticmethod
    def _as_float(value: Any, default: float = 0.0) -> float:
        try:
            return float(value) if value is not None else default
        except (TypeError, ValueError):
            return default

    @classmethod
    def _optional_float(cls, value: Any) -> Optional[float]:
        return None if value is None else cls._as_float(value)

    @staticmethod
    def _normalize_allergen(tag: str) -> str:
        name = tag.rsplit(":", 1)[-1].replace("-", " ").strip()
        aliases = {"soybeans": "Soy", "soya": "Soy", "tree nuts": "Tree Nuts"}
        return aliases.get(name.lower(), name.title())


off_service = OpenFoodFactsService()
