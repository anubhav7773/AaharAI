from pathlib import Path

import pytest
from pydantic import ValidationError

from backend.app.core.config import Settings


def write_env(path: Path, **values: str) -> None:
    path.write_text(
        "\n".join(f"{name}={value}" for name, value in values.items()),
        encoding="utf-8",
    )


@pytest.fixture(autouse=True)
def clear_backend_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in (
        "GEMINI_API_KEY",
        "SUPABASE_URL",
        "SUPABASE_SERVICE_ROLE_KEY",
        "UNRELATED_SETTING",
    ):
        monkeypatch.delenv(name, raising=False)


def test_settings_load_all_values_from_explicit_dotenv(tmp_path: Path) -> None:
    env_file = tmp_path / ".env"
    write_env(
        env_file,
        GEMINI_API_KEY="gemini-test-value",
        SUPABASE_URL="https://example.supabase.co",
        SUPABASE_SERVICE_ROLE_KEY="service-role-test-value",
        UNRELATED_SETTING="ignored",
    )

    settings = Settings(_env_file=env_file)

    assert settings.GEMINI_API_KEY.get_secret_value() == "gemini-test-value"
    assert settings.SUPABASE_URL == "https://example.supabase.co"
    assert settings.SUPABASE_SERVICE_ROLE_KEY.get_secret_value() == (
        "service-role-test-value"
    )
    assert not hasattr(settings, "UNRELATED_SETTING")


@pytest.mark.parametrize(
    "missing_name",
    ("GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"),
)
def test_settings_reports_each_missing_variable_without_values(
    tmp_path: Path, missing_name: str
) -> None:
    values = {
        "GEMINI_API_KEY": "gemini-test-value",
        "SUPABASE_URL": "https://example.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "service-role-test-value",
    }
    values.pop(missing_name)
    env_file = tmp_path / ".env"
    write_env(env_file, **values)

    with pytest.raises(ValidationError) as exc_info:
        Settings(_env_file=env_file)

    message = str(exc_info.value)
    assert missing_name in message
    assert "gemini-test-value" not in message
    assert "service-role-test-value" not in message


def test_default_env_file_is_repository_relative(tmp_path: Path, monkeypatch) -> None:
    env_file = Path("backend/.env").resolve()
    env_file.write_text(
        "GEMINI_API_KEY=temporary-gemini\n"
        "SUPABASE_URL=https://temporary.supabase.co\n"
        "SUPABASE_SERVICE_ROLE_KEY=temporary-service-role\n",
        encoding="utf-8",
    )
    try:
        monkeypatch.chdir(tmp_path)
        settings = Settings()
        assert settings.SUPABASE_URL == "https://temporary.supabase.co"
    finally:
        env_file.unlink()
