"""Verify the public health, CORS, and barcode contracts of a deployment."""

from __future__ import annotations

import sys

import httpx


def test_live_deployment(base_url: str) -> None:
    clean_url = base_url.rstrip("/")
    print(f"Testing live production deployment at: {clean_url}\n")

    with httpx.Client(timeout=25.0, follow_redirects=True) as client:
        print("1. Checking /health ping...")
        try:
            response = client.get(f"{clean_url}/health")
            response.raise_for_status()
            data = response.json()
            if data.get("status") != "healthy":
                raise AssertionError(f"Unexpected health payload: {data}")
            print(f"   OK: {data}")
        except (httpx.HTTPError, ValueError, AssertionError) as error:
            print(f"   Health check failed: {error}")
            raise SystemExit(1) from error

        print("\n2. Verifying CORS preflight handshake...")
        try:
            response = client.options(
                f"{clean_url}/api/v1/scan/street-food",
                headers={
                    "Origin": "https://asiverticals.me",
                    "Access-Control-Request-Method": "GET",
                },
            )
            if response.status_code not in (200, 204):
                raise AssertionError(
                    f"CORS failed with status {response.status_code}"
                )
            print("   OK: CORS preflight allowed.")
        except (httpx.HTTPError, AssertionError) as error:
            print(f"   CORS test failed: {error}")
            raise SystemExit(1) from error

        print("\n3. Testing barcode scan pipeline...")
        try:
            response = client.get(
                f"{clean_url}/api/v1/scan/barcode/3017624010701"
            )
            response.raise_for_status()
            data = response.json()
            if "food_name" not in data:
                raise AssertionError("Response missing food_name")
            if "health_disclaimer" not in data:
                raise AssertionError("Response missing health_disclaimer")
            print(f"   OK: {data['food_name']}")
            print(f"   Disclaimer present: {data['health_disclaimer'][:60]}...")
        except (httpx.HTTPError, ValueError, AssertionError) as error:
            print(f"   Barcode scan failed: {error}")
            raise SystemExit(1) from error

    print("\nSub-Phase 5.1 SUCCESS: deployment is operational and compliant.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            "Usage: python verify_production_deployment.py "
            "https://your-app.onrender.com"
        )
        raise SystemExit(2)
    test_live_deployment(sys.argv[1])
