"""Service health and warm-up endpoint."""

from datetime import datetime, timezone

from fastapi import APIRouter, Response

from app.core.config import settings

router = APIRouter()


@router.get("/health", tags=["System"])
async def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.head("/health", include_in_schema=False)
async def health_head() -> Response:
    """Provide a bodyless liveness response for uptime monitors."""
    return Response(status_code=200)
