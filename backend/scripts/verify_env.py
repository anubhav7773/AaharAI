"""Validate the local backend environment before starting the service."""

from pathlib import Path
import sys

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import settings


def main() -> None:
    if not settings.GEMINI_API_KEY.get_secret_value().strip():
        raise AssertionError("GEMINI_API_KEY is missing!")
    if not settings.SUPABASE_URL.startswith("https://"):
        raise AssertionError("Invalid SUPABASE_URL!")
    if not settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value().strip():
        raise AssertionError("SUPABASE_SERVICE_ROLE_KEY is missing!")

    print(
        "Sub-Phase 1.1 SUCCESS: Config loaded for "
        f"'{settings.PROJECT_NAME}' in '{settings.ENVIRONMENT}' mode."
    )


if __name__ == "__main__":
    main()
