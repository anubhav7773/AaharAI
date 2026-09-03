import asyncio
import hashlib
import json
import logging
from typing import Any, Dict, List, Optional

from supabase import AsyncClient, create_async_client

from app.core.config import settings

logger = logging.getLogger("aaharai.cache")


class FoodCacheService:
    def __init__(self) -> None:
        self.supabase_url = settings.SUPABASE_URL
        self.supabase_key = settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value()
        self._client: Optional[AsyncClient] = None

    async def get_client(self) -> AsyncClient:
        if self._client is None:
            self._client = await create_async_client(
                self.supabase_url, self.supabase_key
            )
        return self._client

    @staticmethod
    def generate_signature_hash(raw_text: str) -> str:
        normalized = " ".join(raw_text.strip().lower().split())
        return hashlib.sha256(normalized.encode("utf-8")).hexdigest()

    async def get_by_barcode(self, barcode: str) -> Optional[Dict[str, Any]]:
        clean_barcode = barcode.strip()
        if not clean_barcode:
            return None
        return await self._get_one("barcode", clean_barcode)

    async def get_by_signature_hash(
        self, signature_hash: str
    ) -> Optional[Dict[str, Any]]:
        clean_hash = signature_hash.strip()
        if not clean_hash:
            return None
        return await self._get_one("signature_hash", clean_hash)

    async def _get_one(
        self, column: str, value: str
    ) -> Optional[Dict[str, Any]]:
        try:
            client = await self.get_client()
            response = (
                await client.table("food_cache")
                .select("*")
                .eq(column, value)
                .limit(1)
                .execute()
            )
            if not response.data:
                return None

            record = self._normalize_record(response.data[0])
        except Exception:
            logger.exception("Cache lookup failed for %s=%s", column, value)
            return None

        # Asynchronously increment hit_count without blocking or failing cache read
        try:
            current_hits = int(record.get("hit_count") or 1)
            record["hit_count"] = current_hits + 1
            asyncio.create_task(
                self._safe_increment_hit_count(client, record["id"], current_hits + 1)
            )
        except Exception:
            logger.warning(
                "Could not schedule hit_count increment for record %s",
                record.get("id"),
            )

        return record

    @staticmethod
    async def _safe_increment_hit_count(
        client: AsyncClient, record_id: str, new_count: int
    ) -> None:
        try:
            await (
                client.table("food_cache")
                .update({"hit_count": new_count})
                .eq("id", record_id)
                .execute()
            )
        except Exception as exc:
            logger.warning(
                "Failed to increment hit_count for record %s: %s", record_id, exc
            )

    async def search_by_food_name(
        self, food_name: str, limit: int = 5
    ) -> List[Dict[str, Any]]:
        query = food_name.strip()
        if not query:
            return []
        bounded_limit = max(1, min(limit, 50))
        try:
            client = await self.get_client()
            response = (
                await client.table("food_cache")
                .select("*")
                .ilike("food_name", f"%{query}%")
                .limit(bounded_limit)
                .execute()
            )
            return [self._normalize_record(row) for row in (response.data or [])]
        except Exception:
            logger.exception("Food cache search failed for %r", query)
            return []

    async def search_street_food(
        self, query: str, limit: int = 5
    ) -> List[Dict[str, Any]]:
        name = query.strip()
        if not name:
            return []
        bounded_limit = max(1, min(limit, 50))
        try:
            client = await self.get_client()
            response = (
                await client.table("food_cache")
                .select("*")
                .eq("source", "street_food")
                .ilike("food_name", f"%{name}%")
                .limit(bounded_limit)
                .execute()
            )
            return [self._normalize_record(row) for row in (response.data or [])]
        except Exception:
            logger.exception("Street food search failed for %r", name)
            return []

    async def save_to_cache(self, item: Dict[str, Any]) -> Dict[str, Any]:
        if not item.get("food_name"):
            raise ValueError("food_name is required to save a cache entry")

        payload = {
            "barcode": item.get("barcode"),
            "signature_hash": item.get("signature_hash"),
            "food_name": item["food_name"],
            "brand_name": item.get("brand_name"),
            "source": item.get("source", "open_food_facts"),
            "ingredients_raw": item.get("ingredients_raw"),
            "parsed_ingredients": item.get("parsed_ingredients", []),
            "nutrients": item.get("nutrients", {}),
            "allergens": item.get("allergens", []),
            "preparation_insights": item.get("preparation_insights"),
        }
        if not payload["barcode"] and not payload["signature_hash"]:
            raw_ingredients = payload["ingredients_raw"]
            if raw_ingredients:
                payload["signature_hash"] = self.generate_signature_hash(
                    raw_ingredients
                )
            else:
                raise ValueError("barcode or signature_hash is required")

        on_conflict = "barcode" if payload["barcode"] else "signature_hash"
        client = await self.get_client()
        response = await (
            client.table("food_cache")
            .upsert(payload, on_conflict=on_conflict)
            .execute()
        )
        if not response.data:
            raise RuntimeError("Supabase returned no cache record after upsert")
        return self._normalize_record(response.data[0])

    @staticmethod
    def _normalize_record(row: Dict[str, Any]) -> Dict[str, Any]:
        normalized = dict(row)
        for key in ("parsed_ingredients", "nutrients", "allergens"):
            value = normalized.get(key)
            if isinstance(value, str):
                try:
                    normalized[key] = json.loads(value)
                except (ValueError, TypeError):
                    logger.warning(
                        "Failed to decode %s as JSON in cache record: %s",
                        key,
                        normalized.get("id"),
                    )
        return normalized


cache_service = FoodCacheService()
