"""Typed application configuration loaded from the backend environment."""

import json
from functools import lru_cache
from pathlib import Path
from typing import List, Union

from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    """Required server-side settings for backend integrations."""

    ENVIRONMENT: str = "development"
    PROJECT_NAME: str = "AaharAi Engine"
    API_V1_STR: str = "/api/v1"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    GEMINI_API_KEY: SecretStr
    GEMINI_MODEL_NAME: str = "gemini-flash-latest"
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: SecretStr
    OFF_BASE_URL: str = "https://world.openfoodfacts.org/api/v2/product"
    OFF_USER_AGENT: str = "AaharAi/1.0 (founder@asiverticals.me)"
    OFF_TIMEOUT_SECONDS: float = 6.0
    BACKEND_CORS_ORIGINS: Union[List[str], str] = ["*"]
    SYSTEM_INSTRUCTION: str = (
        "You are an expert Indian food science and nutrition analyst for AaharAi. "
        "Rules: explain ingredients in plain conversational language; identify FSSAI "
        "allergens and INS additives; use IFCT 2017 baselines for Indian street foods; "
        "and remain educational and neutral without medical claims."
    )

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, value: Union[str, List[str]]) -> List[str]:
        if isinstance(value, str) and not value.startswith("["):
            return [origin.strip() for origin in value.split(",")]
        if isinstance(value, str):
            return json.loads(value)
        if isinstance(value, list):
            return value
        raise ValueError(value)

    @field_validator("GEMINI_API_KEY", "SUPABASE_SERVICE_ROLE_KEY")
    @classmethod
    def validate_secret(cls, value: SecretStr) -> SecretStr:
        if not value.get_secret_value().strip():
            raise ValueError("credential must not be empty")
        return value

    model_config = SettingsConfigDict(
        env_file=str(BACKEND_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    """Return the validated, process-wide settings instance."""

    return Settings()


settings = get_settings()
