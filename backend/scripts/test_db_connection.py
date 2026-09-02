"""Verify that the configured Supabase REST endpoint is reachable."""

from pathlib import Path
import sys

import httpx

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import get_settings


def main() -> None:
    settings = get_settings()
    url = f"{settings.SUPABASE_URL.rstrip('/')}/rest/v1/food_cache"
    headers = {
        "apikey": settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value(),
        "Authorization": (
            f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value()}"
        ),
        "Accept": "application/json",
    }

    response = httpx.get(
        url,
        params={"select": "id", "limit": "1"},
        headers=headers,
        timeout=6.0,
    )
    response.raise_for_status()
    if response.status_code != 200:
        raise RuntimeError(
            f"Supabase food_cache verification returned HTTP {response.status_code}."
        )

    print("Database connected successfully! 'food_cache' table is active and reachable.")


if __name__ == "__main__":
    main()
