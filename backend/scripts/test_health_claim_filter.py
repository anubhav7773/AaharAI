from app.core.health_claim_filter import health_claim_sanitizer


def test_sanitization() -> None:
    dirty_payload = {
        "preparation_insights": "Regular consumption completely cures diabetes and treats hypertension naturally.",
        "parsed_ingredients": [
            {
                "plain_explanation": "An alkaloid that reverses diabetes and burns fat fast.",
                "regulatory_footnote": "Clinically proven miracle weight loss treatment.",
            }
        ],
    }
    cleaned = health_claim_sanitizer.sanitize_food_payload(dirty_payload)
    assert "cures" not in cleaned["preparation_insights"].lower()
    assert "treats" not in cleaned["preparation_insights"].lower()
    assert "reverses" not in cleaned["parsed_ingredients"][0]["plain_explanation"].lower()
    assert "miracle weight loss" not in cleaned["parsed_ingredients"][0]["regulatory_footnote"].lower()
    assert cleaned["health_disclaimer"] == health_claim_sanitizer.MANDATORY_DISCLAIMER


if __name__ == "__main__":
    test_sanitization()
    print("Health claim sanitization passed.")
