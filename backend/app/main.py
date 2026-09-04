"""FastAPI application entrypoint."""

import sys
import time
from contextlib import asynccontextmanager
from pathlib import Path

# Ensure backend root directory is in sys.path
_backend_root = Path(__file__).resolve().parent.parent
if str(_backend_root) not in sys.path:
    sys.path.insert(0, str(_backend_root))

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.endpoints import health
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.health_claim_filter import HealthClaimMiddleware
from app.services.off_service import off_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"[AaharAI] === Starting {settings.PROJECT_NAME} ({settings.ENVIRONMENT}) ===", flush=True)
    routes = [f"{list(r.methods) if hasattr(r, 'methods') else ''} {r.path}" for r in app.routes]
    print(f"[AaharAI] Active Routes ({len(routes)}): {routes}", flush=True)
    yield
    print(f"[AaharAI] === Shutting down {settings.PROJECT_NAME} ===", flush=True)
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


@app.middleware("http")
async def log_requests_middleware(request: Request, call_next):
    start_time = time.perf_counter()
    method = request.method
    url_path = request.url.path
    query = request.url.query
    client_ip = request.client.host if request.client else "unknown"
    query_str = f"?{query}" if query else ""

    print(f"[AaharAI-API] --> {method} {url_path}{query_str} from {client_ip}", flush=True)
    try:
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start_time) * 1000
        print(
            f"[AaharAI-API] <-- {method} {url_path} -> {response.status_code} ({duration_ms:.1f}ms)",
            flush=True,
        )
        return response
    except Exception as exc:
        duration_ms = (time.perf_counter() - start_time) * 1000
        print(
            f"[AaharAI-API] <XX {method} {url_path} FAILED ({duration_ms:.1f}ms): {exc}",
            flush=True,
        )
        raise


# API v1 endpoints
app.include_router(api_router, prefix=settings.API_V1_STR)

# Root-level health and uptime endpoints for Render health checks & uptime monitors
app.include_router(health.router)

