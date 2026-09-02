import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/core/models/enums.dart';
import 'package:aahar_ai/core/models/food_models.dart';
import 'package:aahar_ai/core/models/food_log_model.dart';

void main() {
  group('Sub-Phase 1.3: Data Models Serialization Tests', () {
    test('parses and round-trips the FastAPI food contract', () {
      final mockJson = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'barcode': '3017624010701',
        'food_name': 'Nutella Hazelnut Spread',
        'brand_name': 'Ferrero',
        'source': 'open_food_facts',
        'serving_size': '100g',
        'nutrients': {
          'calories': 539.0,
          'protein_g': 6.3,
          'carbs_g': 56.3,
          'fat_g': 30.9,
          'saturated_fat_g': 10.6,
          'added_sugar_g': 56.3,
          'sodium_mg': 40.0,
        },
        'parsed_ingredients': [
          {
            'name': 'Soya Lecithin',
            'ins_code': 'INS 322',
            'safety': 'safe',
            'plain_explanation': 'Natural emulsifier to bind fat and cocoa.',
            'regulatory_footnote': 'FSSAI Permitted Emulsifier',
          },
        ],
        'allergens': ['Milk', 'Soy', 'Tree Nuts'],
        'preparation_insights': null,
      };

      final item = FoodItem.fromJson(mockJson);

      expect(item.foodName, 'Nutella Hazelnut Spread');
      expect(item.nutrients.calories, 539.0);
      expect(item.parsedIngredients.first.safety, IngredientSafety.safe);
      expect(item.allergens, contains('Tree Nuts'));
      expect(item.source, FoodSourceType.openFoodFacts);
      expect(item.toJson()['nutrients']['calories'], 539.0);
    });

    test('serializes and deserializes a diary log', () {
      final entry = FoodLogEntry(
        id: 'log-id',
        userId: 'user-id',
        foodName: 'Poha',
        servingQuantityG: 250,
        caloriesConsumed: 320,
        consumedMacros: {'protein_g': 8},
        mealType: MealCategoryType.breakfast,
        loggedAt: DateTime.utc(2026, 1, 1),
      );

      final decoded = FoodLogEntry.fromJson(entry.toJson());

      expect(decoded.mealType, MealCategoryType.breakfast);
      expect(decoded.loggedAt, entry.loggedAt);
      expect(decoded.servingQuantityG, 250);
    });
  });
}
