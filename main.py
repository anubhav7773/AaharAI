"""Root application entrypoint for Render and cloud deployments."""

import sys
from pathlib import Path

# Add backend directory to sys.path so 'app' imports work
_backend_path = Path(__file__).resolve().parent / "backend"
if str(_backend_path) not in sys.path:
    sys.path.insert(0, str(_backend_path))

from app.main import app  # noqa: E402, F401

__all__ = ["app"]
