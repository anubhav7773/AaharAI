from app.schemas.food import (
    GeminiFoodExtractionSchema,
    IngredientSafetyEnum,
    NutrientProfileSchema,
    ParsedIngredientSchema,
)


def test_parsed_ingredient_schema_accepts_standard_and_alias_keys():
    standard_data = {
        "name": "INS 322",
        "ins_code": "INS 322",
        "safety": "safe",
        "plain_explanation": "Soya lecithin",
        "regulatory_footnote": "Permitted additive",
    }
    item1 = ParsedIngredientSchema.model_validate(standard_data)
    assert item1.safety == IngredientSafetyEnum.safe
    assert item1.plain_explanation == "Soya lecithin"
    assert item1.regulatory_footnote == "Permitted additive"

    alias_data = {
        "name": "Tartrazine",
        "category": "avoid",
        "simple_explanation": "Synthetic yellow dye",
        "health_note": "FSSAI restricted for infant food",
    }
    item2 = ParsedIngredientSchema.model_validate(alias_data)
    assert item2.safety == IngredientSafetyEnum.avoid
    assert item2.plain_explanation == "Synthetic yellow dye"
    assert item2.regulatory_footnote == "FSSAI restricted for infant food"


def test_nutrient_profile_schema_accepts_aliases():
    data = {
        "calories_100g": 450.0,
        "protein_100g": 12.5,
        "carbs_100g": 60.0,
        "fat_100g": 18.0,
        "fiber_100g": 5.0,
    }
    profile = NutrientProfileSchema.model_validate(data)
    assert profile.calories == 450.0
    assert profile.protein_g == 12.5
    assert profile.carbs_g == 60.0
    assert profile.fat_g == 18.0
    assert profile.fiber_g == 5.0


def test_gemini_food_extraction_schema_round_trip():
    payload = {
        "food_name": "Pani Puri",
        "nutrients": {
            "calories": 210.0,
            "protein_g": 3.5,
            "carbs_g": 34.0,
            "fat_g": 7.0,
        },
        "parsed_ingredients": [
            {
                "name": "Mint Flavored Water",
                "safety": "safe",
                "plain_explanation": "Spiced water",
            }
        ],
        "allergens": ["Gluten/Wheat"],
    }
    extracted = GeminiFoodExtractionSchema.model_validate(payload)
    assert extracted.food_name == "Pani Puri"
    assert extracted.nutrients.calories == 210.0
    assert len(extracted.parsed_ingredients) == 1
    assert extracted.parsed_ingredients[0].safety == IngredientSafetyEnum.safe
