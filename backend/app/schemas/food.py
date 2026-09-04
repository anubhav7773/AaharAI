"""Structured food extraction contracts returned by Gemini."""

from enum import Enum
from typing import List, Optional

from pydantic import AliasChoices, BaseModel, ConfigDict, Field


class IngredientSafetyEnum(str, Enum):
    safe = "safe"
    moderate = "moderate"
    avoid = "avoid"


class FoodSourceEnum(str, Enum):
    open_food_facts = "open_food_facts"
    gemini_vision = "gemini_vision"
    street_food = "street_food"


class ParsedIngredientSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    name: str = Field(description="Normalized common ingredient or chemical name")
    ins_code: Optional[str] = Field(
        default=None, description="FSSAI INS / E-number code if identified"
    )
    safety: IngredientSafetyEnum = Field(
        validation_alias=AliasChoices("safety", "category"),
        description="Strictly safe, moderate, or avoid",
    )
    plain_explanation: str = Field(
        validation_alias=AliasChoices("plain_explanation", "simple_explanation"),
        description="One-line explanation in everyday simple language",
    )
    regulatory_footnote: Optional[str] = Field(
        default=None,
        validation_alias=AliasChoices("regulatory_footnote", "health_note"),
        description="Brief FSSAI or ICMR threshold note",
    )


class NutrientProfileSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    calories: float = Field(
        default=0.0,
        validation_alias=AliasChoices("calories", "calories_100g"),
        description="Energy in kcal per 100g or serving",
    )
    protein_g: float = Field(
        default=0.0,
        validation_alias=AliasChoices("protein_g", "protein_100g", "protein"),
    )
    carbs_g: float = Field(
        default=0.0,
        validation_alias=AliasChoices("carbs_g", "carbs_100g", "carbs"),
    )
    fat_g: float = Field(
        default=0.0,
        validation_alias=AliasChoices("fat_g", "fat_100g", "fat"),
    )
    saturated_fat_g: Optional[float] = Field(
        default=None,
        validation_alias=AliasChoices(
            "saturated_fat_g", "saturated_fat_100g", "saturated-fat_100g"
        ),
    )
    added_sugar_g: Optional[float] = Field(
        default=None,
        validation_alias=AliasChoices("added_sugar_g", "sugars_100g", "sugars"),
    )
    sodium_mg: Optional[float] = Field(
        default=None,
        validation_alias=AliasChoices("sodium_mg", "sodium_100g", "sodium"),
    )
    fiber_g: Optional[float] = Field(
        default=None,
        validation_alias=AliasChoices("fiber_g", "fiber_100g", "fiber"),
    )


class GeminiFoodExtractionSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    food_name: str
    brand_name: Optional[str] = None
    serving_size: Optional[str] = None
    nutrients: NutrientProfileSchema = Field(default_factory=NutrientProfileSchema)
    parsed_ingredients: List[ParsedIngredientSchema] = Field(default_factory=list)
    allergens: List[str] = Field(default_factory=list)
    preparation_insights: Optional[str] = None

