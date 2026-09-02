"""Typed application configuration loaded from the backend environment."""

from functools import lru_cache
from pathlib import Path

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    """Required server-side settings for backend integrations."""

    GEMINI_API_KEY: SecretStr
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: SecretStr

    model_config = SettingsConfigDict(
        env_file=str(BACKEND_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    """Return the validated, process-wide settings instance."""

    return Settings()
