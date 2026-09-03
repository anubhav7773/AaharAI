"""Service health and warm-up endpoint."""

from datetime import datetime, timezone

from fastapi import APIRouter, Response

from app.core.config import settings

router = APIRouter()


@router.get("/health", tags=["System"])
async def health_check() -> dict[str, str]:
    return _health_payload()


@router.get("/uptime", tags=["System"])
async def uptime_check() -> dict[str, str]:
    """Dependency-free endpoint for external uptime monitors."""
    return _health_payload()


def _health_payload() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.head("/health", include_in_schema=False)
async def health_head() -> Response:
    """Provide a bodyless liveness response for uptime monitors."""
    return Response(status_code=200)
