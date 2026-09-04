import logging
from typing import Any, Dict, Optional

import httpx

from app.core.config import settings

logger = logging.getLogger("aaharai.off")


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
        self._client: Optional[httpx.AsyncClient] = None

    async def get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=self.timeout,
                headers=self.headers,
                limits=httpx.Limits(max_keepalive_connections=20, max_connections=50),
            )
        return self._client

    async def close(self) -> None:
        if self._client is not None and not self._client.is_closed:
            await self._client.aclose()

    async def fetch_product_by_barcode(
        self, barcode: str
    ) -> Optional[Dict[str, Any]]:
        """Return normalized product data, or None when OFF cannot provide it."""
        clean_barcode = barcode.strip()
        if not clean_barcode:
            return None

        url = f"{self.base_url}/{clean_barcode}.json"
        try:
            client = await self.get_client()
            response = await client.get(
                url,
                params={"fields": self.requested_fields},
            )
            if response.status_code == 404:
                logger.info("Barcode %s not found in Open Food Facts", clean_barcode)
                return None
            if response.status_code == 429:
                logger.warning(
                    "Open Food Facts rate limit hit (429) for barcode %s", clean_barcode
                )
                return None
            if response.status_code != 200:
                logger.warning(
                    "Open Food Facts returned HTTP %d for barcode %s",
                    response.status_code,
                    clean_barcode,
                )
                return None

            data = response.json()
            if data.get("status") in (0, "0") or "product" not in data:
                return None
            product = data["product"]
            if not isinstance(product, dict):
                return None
            product_name = (product.get("product_name") or "").strip()
            if not product_name:
                logger.info("Open Food Facts entry for %s lacks product_name; treating as missing", clean_barcode)
                return None
            return self._normalize_off_data(clean_barcode, product)
        except httpx.TimeoutException:
            logger.warning(
                "Open Food Facts request timed out for barcode %s", clean_barcode
            )
            return None
        except httpx.RequestError as exc:
            logger.warning(
                "Open Food Facts network error for barcode %s: %s", clean_barcode, exc
            )
            return None
        except Exception as exc:
            logger.exception(
                "Unexpected error fetching barcode %s from Open Food Facts: %s",
                clean_barcode,
                exc,
            )
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
