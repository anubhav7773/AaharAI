import '../../../core/utils/safety_filter.dart';

enum SafetyCategory {
  safe,
  moderate,
  avoid;

  static SafetyCategory fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'avoid':
        return SafetyCategory.avoid;
      case 'moderate':
        return SafetyCategory.moderate;
      case 'safe':
      default:
        return SafetyCategory.safe;
    }
  }

  String get label {
    switch (this) {
      case SafetyCategory.safe:
        return 'Safe';
      case SafetyCategory.moderate:
        return 'Moderate';
      case SafetyCategory.avoid:
        return 'Avoid';
    }
  }
}

class IngredientItem {
  final String name;
  final String simpleExplanation;
  final SafetyCategory category;
  final String healthNote;

  IngredientItem({
    required this.name,
    required this.simpleExplanation,
    required this.category,
    required this.healthNote,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    final rawSafety = json['category'] as String? ?? json['safety'] as String?;
    final rawExplanation = json['simple_explanation'] as String? ??
        json['plain_explanation'] as String? ??
        '';
    final rawHealthNote = json['health_note'] as String? ??
        json['regulatory_footnote'] as String? ??
        '';

    return IngredientItem(
      name: json['name'] as String? ?? 'Ingredient',
      simpleExplanation: HealthClaimFilter.sanitizeResponse(rawExplanation),
      category: SafetyCategory.fromString(rawSafety),
      healthNote: HealthClaimFilter.sanitizeResponse(rawHealthNote),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'simple_explanation': simpleExplanation,
        'plain_explanation': simpleExplanation,
        'category': category.name,
        'safety': category.name,
        'health_note': healthNote,
        'regulatory_footnote': healthNote,
      };
}

class NutrientProfile {
  final double calories100g;
  final double protein100g;
  final double carbs100g;
  final double fat100g;
  final double fiber100g;

  NutrientProfile({
    this.calories100g = 0.0,
    this.protein100g = 0.0,
    this.carbs100g = 0.0,
    this.fat100g = 0.0,
    this.fiber100g = 0.0,
  });

  factory NutrientProfile.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return NutrientProfile(
      calories100g: parseDouble(json['calories_100g'] ?? json['calories']),
      protein100g: parseDouble(
        json['protein_100g'] ?? json['protein_g'] ?? json['protein'],
      ),
      carbs100g: parseDouble(
        json['carbs_100g'] ?? json['carbs_g'] ?? json['carbs'],
      ),
      fat100g: parseDouble(
        json['fat_100g'] ?? json['fat_g'] ?? json['fat'],
      ),
      fiber100g: parseDouble(
        json['fiber_100g'] ?? json['fiber_g'] ?? json['fiber'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'calories_100g': calories100g,
        'calories': calories100g,
        'protein_100g': protein100g,
        'protein_g': protein100g,
        'carbs_100g': carbs100g,
        'carbs_g': carbs100g,
        'fat_100g': fat100g,
        'fat_g': fat100g,
        'fiber_100g': fiber100g,
        'fiber_g': fiber100g,
      };
}

class FoodAnalysisResponse {
  final String foodName;
  final String? brandName;
  final String source; // 'open_food_facts' | 'gemini_vision' | 'street_food'
  final NutrientProfile nutrients;
  final List<String> allergensDetected;
  final List<IngredientItem> ingredients;
  final String? preparationInsights;

  FoodAnalysisResponse({
    required this.foodName,
    this.brandName,
    required this.source,
    required this.nutrients,
    this.allergensDetected = const [],
    this.ingredients = const [],
    this.preparationInsights,
  });

  factory FoodAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final rawNutrients = json['nutrients'];
    final rawIngredients = json['ingredients'] ?? json['parsed_ingredients'];
    final rawAllergens = json['allergens_detected'] ?? json['allergens'];

    return FoodAnalysisResponse(
      foodName: json['food_name'] as String? ?? 'Food Product',
      brandName: json['brand_name'] as String?,
      source: json['source'] as String? ?? 'open_food_facts',
      nutrients: rawNutrients is Map
          ? NutrientProfile.fromJson(
              Map<String, dynamic>.from(rawNutrients),
            )
          : NutrientProfile(),
      allergensDetected: rawAllergens is List
          ? rawAllergens.map((e) => e.toString()).toList()
          : const [],
      ingredients: rawIngredients is List
          ? rawIngredients
              .whereType<Map>()
              .map(
                (e) => IngredientItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      preparationInsights: json['preparation_insights'] != null
          ? HealthClaimFilter.sanitizeResponse(
              json['preparation_insights'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'food_name': foodName,
        'brand_name': brandName,
        'source': source,
        'nutrients': nutrients.toJson(),
        'allergens_detected': allergensDetected,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'preparation_insights': preparationInsights,
      };
}
