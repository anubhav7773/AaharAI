"""Minimal backend startup boundary."""

from .core.config import Settings, get_settings

# Validate required configuration as soon as the backend package starts.
settings: Settings = get_settings()
