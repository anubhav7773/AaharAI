"""Google Play health-policy response sanitization."""

import copy
import json
import logging
import re
from typing import Any

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("aaharai.compliance")


class HealthClaimSanitizer:
    PROHIBITED_PATTERNS = (
        (r"\b(cures?|curing)\b", "supports nutritional balance for"),
        (
            r"\b(treats?|treating|treatment of)\b",
            "is traditionally associated with dietary care in",
        ),
        (
            r"\b(prevents?|preventing|prevention of)\b",
            "is consumed to reduce risk factors associated with",
        ),
        (r"\b(heals?|healing)\b", "aids nutritional intake for"),
        (
            r"\b(reverses?|reversing)\s+(diabetes|hypertension|obesity)\b",
            r"supports dietary habits for \2",
        ),
        (r"\b(medical advice|prescribed for|clinical diagnosis)\b", "dietary educational context"),
        (r"\b(anti-cancer|cancer fighting)\b", "antioxidant-rich"),
        (r"\b(burns fat fast|miracle weight loss)\b", "supports calorie-conscious diets"),
    )

    MANDATORY_DISCLAIMER = (
        "AaharAi provides general food education and nutritional insights based on "
        "FSSAI/ICMR standards. It is not a medical device, diagnostic tool, or "
        "clinical prescription service."
    )

    @classmethod
    def sanitize_text(cls, text: str) -> str:
        sanitized = text or ""
        for pattern, replacement in cls.PROHIBITED_PATTERNS:
            sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)
        return sanitized

    @classmethod
    def _sanitize_value(cls, value: Any) -> Any:
        if isinstance(value, str):
            return cls.sanitize_text(value)
        if isinstance(value, dict):
            return {key: cls._sanitize_value(item) for key, item in value.items()}
        if isinstance(value, list):
            return [cls._sanitize_value(item) for item in value]
        return value

    @classmethod
    def sanitize_food_payload(cls, data: dict[str, Any]) -> dict[str, Any]:
        cleaned = cls._sanitize_value(copy.deepcopy(data))
        cleaned["health_disclaimer"] = cls.MANDATORY_DISCLAIMER
        return cleaned


health_claim_sanitizer = HealthClaimSanitizer()


class HealthClaimMiddleware(BaseHTTPMiddleware):
    """Sanitize JSON scan responses at the final API boundary."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        if "/scan/" not in request.url.path or not response.headers.get(
            "content-type", ""
        ).startswith("application/json"):
            return response

        body = b"".join([chunk async for chunk in response.body_iterator])
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            return Response(
                content=body,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
            )
        if not isinstance(payload, dict):
            return Response(
                content=body,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
            )
        cleaned = health_claim_sanitizer.sanitize_food_payload(payload)
        headers = {
            key: value
            for key, value in response.headers.items()
            if key.lower() not in {"content-length", "content-encoding"}
        }
        return Response(
            content=json.dumps(cleaned),
            status_code=response.status_code,
            headers=headers,
            media_type="application/json",
        )
