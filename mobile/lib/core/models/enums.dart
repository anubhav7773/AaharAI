/// FSSAI safety classification for deconstructed ingredients.
enum IngredientSafety {
  safe,
  moderate,
  avoid;

  static IngredientSafety fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'moderate':
        return moderate;
      case 'avoid':
        return avoid;
      case 'safe':
      default:
        return safe;
    }
  }

  String toValue() => name;
}

/// Food source pipeline identifier.
enum FoodSourceType {
  openFoodFacts,
  geminiVision,
  streetFood;

  static FoodSourceType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'gemini_vision':
        return geminiVision;
      case 'street_food':
        return streetFood;
      case 'open_food_facts':
      default:
        return openFoodFacts;
    }
  }

  String toValue() {
    switch (this) {
      case openFoodFacts:
        return 'open_food_facts';
      case geminiVision:
        return 'gemini_vision';
      case streetFood:
        return 'street_food';
    }
  }
}

/// User diary meal categories.
enum MealCategoryType {
  breakfast,
  lunch,
  dinner,
  snack;

  static MealCategoryType fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snack':
      default:
        return snack;
    }
  }

  String toValue() => name;
}
