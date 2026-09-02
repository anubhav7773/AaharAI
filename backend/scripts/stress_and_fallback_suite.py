"""Run pre-release resilience checks against a local or staging API."""

from __future__ import annotations

import argparse
import asyncio
import base64
import time
from typing import Any

import httpx

from app.core.health_claim_filter import health_claim_sanitizer

DEFAULT_BASE_URL = "http://127.0.0.1:8000"
BARCODE = "3017624010701"
UNKNOWN_BARCODE = "0000000000000"

# A valid 1x1 white JPEG keeps this script independent of Pillow.
BLANK_JPEG = base64.b64decode(
    "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////"
    "2wBDAf//////////////////////////////////////////////////////////////////////////////////////"
    "wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAA"
    "/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAA"
    "AAAAAAAAAAB/2gAIAQMBAT8BH//EABQRAQAAAAAAAAAAAAAAAAAAABD/2gAIAQIBAT8BH//EABQQAQAAAA"
    "AAAAAAAAAAAAAAABD/2gAIAQEABj8Cf//Z"
)


async def _test_unknown_barcode(client: httpx.AsyncClient) -> None:
    response = await client.get(f"/api/v1/scan/barcode/{UNKNOWN_BARCODE}")
    assert response.status_code == 404, response.text
    detail = response.json().get("detail", "")
    assert "OCR" in detail, f"Fallback guidance missing: {detail}"


async def _test_concurrent_cache_hits(client: httpx.AsyncClient) -> None:
    started = time.perf_counter()
    responses = await asyncio.gather(
        *(client.get(f"/api/v1/scan/barcode/{BARCODE}") for _ in range(10))
    )
    elapsed_ms = (time.perf_counter() - started) * 1000
    successful = sum(response.status_code == 200 for response in responses)
    assert successful == 10, [
        response.status_code for response in responses if response.status_code != 200
    ]
    print(f"    10/10 cache reads succeeded in {elapsed_ms:.1f} ms")
    if elapsed_ms > 50:
        print("    Warning: warm-hit batch exceeded the 50 ms target.")


async def _test_blank_image(client: httpx.AsyncClient) -> None:
    response = await client.post(
        "/api/v1/scan/vision",
        files={"file": ("blank.jpg", BLANK_JPEG, "image/jpeg")},
    )
    assert response.status_code in (200, 400, 413, 500), response.text
    if response.status_code != 200:
        assert "detail" in response.json(), response.text


async def _test_street_food(client: httpx.AsyncClient) -> None:
    response = await client.get(
        "/api/v1/scan/street-food",
        params={"dish_name": "Special Cheesy Paneer Tikka Roll"},
    )
    assert response.status_code == 200, response.text
    data = response.json()
    nutrients = data.get("nutrients", {})
    assert nutrients.get("calories", 0) > 0, data
    insights = data.get("preparation_insights", "")
    assert insights, data
    assert "health_disclaimer" in data, data
    assert any(term in insights.lower() for term in ("oil", "flour")), insights


def _test_claim_sanitization() -> None:
    payload: dict[str, Any] = {
        "preparation_insights": "This cures illness and treats disease.",
        "parsed_ingredients": [
            {"plain_explanation": "It reverses diabetes."},
        ],
    }
    cleaned = health_claim_sanitizer.sanitize_food_payload(payload)
    text = str(cleaned)
    for prohibited in ("cure", "treat", "reverses diabetes"):
        assert prohibited not in text.lower(), text
    assert "not a medical device" in cleaned["health_disclaimer"].lower()


async def run_suite(base_url: str) -> int:
    print("=" * 70)
    print("  AAHARAI ENGINE - PRE-RELEASE STRESS & FALLBACK TEST SUITE")
    print("=" * 70)

    async with httpx.AsyncClient(
        base_url=base_url.rstrip("/"), timeout=30.0
    ) as client:
        try:
            health = await client.get("/health")
            health.raise_for_status()
            assert health.json().get("status") == "healthy", health.text
            print("OK Service is healthy.\n")
        except (httpx.HTTPError, ValueError, AssertionError) as error:
            print(f"FAILED Service unavailable: {error}")
            return 1

        checks = [
            ("Unregistered barcode fallback", _test_unknown_barcode(client)),
            ("Concurrent cache reads", _test_concurrent_cache_hits(client)),
            ("Blank image handling", _test_blank_image(client)),
            ("Street-food safety response", _test_street_food(client)),
        ]
        failures = 0
        for name, check in checks:
            try:
                print(f"[TEST] {name}...")
                await check
                print("    PASS")
            except (httpx.HTTPError, ValueError, AssertionError) as error:
                failures += 1
                print(f"    FAIL: {error}")

        try:
            print("[TEST] Prohibited claim sanitization...")
            _test_claim_sanitization()
            print("    PASS")
        except AssertionError as error:
            failures += 1
            print(f"    FAIL: {error}")

    print("\n" + ("ALL CHECKS PASSED" if failures == 0 else f"{failures} CHECK(S) FAILED"))
    return int(failures != 0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_url", nargs="?", default=DEFAULT_BASE_URL)
    args = parser.parse_args()
    raise SystemExit(asyncio.run(run_suite(args.base_url)))


if __name__ == "__main__":
    main()
