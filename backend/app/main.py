"""FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints import health
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.health_claim_filter import HealthClaimMiddleware
from app.services.off_service import off_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await off_service.close()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(HealthClaimMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API v1 endpoints
app.include_router(api_router, prefix=settings.API_V1_STR)

# Root-level health and uptime endpoints for Render health checks & uptime monitors
app.include_router(health.router)
