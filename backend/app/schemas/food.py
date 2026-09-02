"""Structured food extraction contracts returned by Gemini."""

from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class IngredientSafetyEnum(str, Enum):
    safe = "safe"
    moderate = "moderate"
    avoid = "avoid"


class FoodSourceEnum(str, Enum):
    open_food_facts = "open_food_facts"
    gemini_vision = "gemini_vision"
    street_food = "street_food"


class ParsedIngredientSchema(BaseModel):
    name: str = Field(description="Normalized common ingredient or chemical name")
    ins_code: Optional[str] = Field(
        default=None, description="FSSAI INS / E-number code if identified"
    )
    safety: IngredientSafetyEnum = Field(
        description="Strictly safe, moderate, or avoid"
    )
    plain_explanation: str = Field(
        description="One-line explanation in everyday simple language"
    )
    regulatory_footnote: Optional[str] = Field(
        default=None, description="Brief FSSAI or ICMR threshold note"
    )


class NutrientProfileSchema(BaseModel):
    calories: float = Field(description="Energy in kcal per 100g or serving")
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    saturated_fat_g: Optional[float] = None
    added_sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None
    fiber_g: Optional[float] = None


class GeminiFoodExtractionSchema(BaseModel):
    food_name: str
    brand_name: Optional[str] = None
    serving_size: Optional[str] = None
    nutrients: NutrientProfileSchema
    parsed_ingredients: List[ParsedIngredientSchema] = Field(default_factory=list)
    allergens: List[str] = Field(default_factory=list)
    preparation_insights: Optional[str] = None
