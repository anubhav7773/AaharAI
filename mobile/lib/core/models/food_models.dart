import 'enums.dart';

class ParsedIngredient {
  final String name;
  final String? insCode;
  final IngredientSafety safety;
  final String plainExplanation;
  final String? regulatoryFootnote;

  const ParsedIngredient({
    required this.name,
    this.insCode,
    required this.safety,
    required this.plainExplanation,
    this.regulatoryFootnote,
  });

  factory ParsedIngredient.fromJson(Map<String, dynamic> json) {
    return ParsedIngredient(
      name: json['name'] as String? ?? 'Unknown Ingredient',
      insCode: json['ins_code'] as String?,
      safety: IngredientSafety.fromString(
        json['safety'] as String? ?? json['category'] as String?,
      ),
      plainExplanation: json['plain_explanation'] as String? ??
          json['simple_explanation'] as String? ??
          '',
      regulatoryFootnote: json['regulatory_footnote'] as String? ??
          json['health_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'ins_code': insCode,
        'safety': safety.toValue(),
        'category': safety.toValue(),
        'plain_explanation': plainExplanation,
        'simple_explanation': plainExplanation,
        'regulatory_footnote': regulatoryFootnote,
        'health_note': regulatoryFootnote,
      };
}

class NutrientProfile {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? saturatedFatG;
  final double? addedSugarG;
  final double? sodiumMg;
  final double? fiberG;

  const NutrientProfile({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.saturatedFatG,
    this.addedSugarG,
    this.sodiumMg,
    this.fiberG,
  });

  factory NutrientProfile.fromJson(Map<String, dynamic> json) {
    double? number(String primary, [List<String> aliases = const []]) {
      if (json[primary] != null) return (json[primary] as num?)?.toDouble();
      for (final alias in aliases) {
        if (json[alias] != null) return (json[alias] as num?)?.toDouble();
      }
      return null;
    }

    return NutrientProfile(
      calories: number('calories', ['calories_100g']) ?? 0,
      proteinG: number('protein_g', ['protein_100g', 'protein']) ?? 0,
      carbsG: number('carbs_g', ['carbs_100g', 'carbs']) ?? 0,
      fatG: number('fat_g', ['fat_100g', 'fat']) ?? 0,
      saturatedFatG: number(
        'saturated_fat_g',
        ['saturated_fat_100g', 'saturated-fat_100g'],
      ),
      addedSugarG: number('added_sugar_g', ['sugars_100g', 'sugars']),
      sodiumMg: number('sodium_mg', ['sodium_100g', 'sodium']),
      fiberG: number('fiber_g', ['fiber_100g', 'fiber']),
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'calories_100g': calories,
        'protein_g': proteinG,
        'protein_100g': proteinG,
        'protein': proteinG,
        'carbs_g': carbsG,
        'carbs_100g': carbsG,
        'carbs': carbsG,
        'fat_g': fatG,
        'fat_100g': fatG,
        'fat': fatG,
        'saturated_fat_g': saturatedFatG,
        'added_sugar_g': addedSugarG,
        'sodium_mg': sodiumMg,
        'fiber_g': fiberG,
        'fiber_100g': fiberG,
        'fiber': fiberG,
      };
}

class FoodItem {
  final String? id;
  final String? barcode;
  final String foodName;
  final String? brandName;
  final FoodSourceType source;
  final String? servingSize;
  final NutrientProfile nutrients;
  final List<ParsedIngredient> parsedIngredients;
  final List<String> allergens;
  final String? preparationInsights;

  const FoodItem({
    this.id,
    this.barcode,
    required this.foodName,
    this.brandName,
    required this.source,
    this.servingSize,
    required this.nutrients,
    this.parsedIngredients = const [],
    this.allergens = const [],
    this.preparationInsights,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final nutrientJson = json['nutrients'];
    final ingredientJson = json['parsed_ingredients'] ?? json['ingredients'];
    final allergenJson = json['allergens'] ?? json['allergens_detected'];

    return FoodItem(
      id: json['id'] as String?,
      barcode: json['barcode'] as String?,
      foodName: json['food_name'] as String? ?? 'Unnamed Food',
      brandName: json['brand_name'] as String?,
      source: FoodSourceType.fromString(json['source'] as String?),
      servingSize: json['serving_size'] as String?,
      nutrients: nutrientJson is Map
          ? NutrientProfile.fromJson(Map<String, dynamic>.from(nutrientJson))
          : const NutrientProfile(
              calories: 0,
              proteinG: 0,
              carbsG: 0,
              fatG: 0,
            ),
      parsedIngredients: ingredientJson is List
          ? ingredientJson
              .whereType<Map>()
              .map(
                (item) => ParsedIngredient.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      allergens: allergenJson is List
          ? allergenJson.map((value) => value.toString()).toList()
          : const [],
      preparationInsights: json['preparation_insights'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'food_name': foodName,
        'brand_name': brandName,
        'source': source.toValue(),
        'serving_size': servingSize,
        'nutrients': nutrients.toJson(),
        'parsed_ingredients':
            parsedIngredients.map((ingredient) => ingredient.toJson()).toList(),
        'ingredients':
            parsedIngredients.map((ingredient) => ingredient.toJson()).toList(),
        'allergens': allergens,
        'allergens_detected': allergens,
        'preparation_insights': preparationInsights,
      };
}
