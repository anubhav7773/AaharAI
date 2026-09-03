import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/core/models/enums.dart';
import 'package:aahar_ai/core/models/food_models.dart';
import 'package:aahar_ai/core/models/food_log_model.dart';
import 'package:aahar_ai/features/analysis/models/food_analysis_model.dart';

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
          'fiber_g': 3.2,
        },
        'parsed_ingredients': [
          {
            'name': 'Soya Lecithin',
            'ins_code': 'INS 322',
            'safety': 'safe',
            'plain_explanation': 'Natural emulsifier to bind fat and cocoa.',
            'regulatory_footnote': 'FSSAI Permitted Emulsifier',
          },
          {
            'name': 'Palm Oil',
            'ins_code': null,
            'safety': 'moderate',
            'plain_explanation': 'Refined vegetable lipid.',
            'regulatory_footnote': 'High saturated fat content.',
          },
          {
            'name': 'Tartrazine',
            'ins_code': 'INS 102',
            'safety': 'avoid',
            'plain_explanation': 'Azo dye.',
            'regulatory_footnote': 'Restricted by FSSAI for infants.',
          },
        ],
        'allergens': ['Milk', 'Soy', 'Tree Nuts'],
        'preparation_insights': 'Processed in confectionery plant.',
      };

      final item = FoodItem.fromJson(mockJson);

      expect(item.foodName, 'Nutella Hazelnut Spread');
      expect(item.nutrients.calories, 539.0);
      expect(item.nutrients.proteinG, 6.3);
      expect(item.nutrients.fiberG, 3.2);
      expect(item.parsedIngredients[0].safety, IngredientSafety.safe);
      expect(item.parsedIngredients[1].safety, IngredientSafety.moderate);
      expect(item.parsedIngredients[2].safety, IngredientSafety.avoid);
      expect(item.allergens, contains('Tree Nuts'));
      expect(item.source, FoodSourceType.openFoodFacts);

      // Verify the critical Bridge to FoodAnalysisResponse
      final analysis = FoodAnalysisResponse.fromJson(item.toJson());
      expect(analysis.foodName, 'Nutella Hazelnut Spread');
      expect(analysis.nutrients.calories100g, 539.0);
      expect(analysis.nutrients.protein100g, 6.3);
      expect(analysis.nutrients.carbs100g, 56.3);
      expect(analysis.nutrients.fat100g, 30.9);
      expect(analysis.nutrients.fiber100g, 3.2);

      // Verify safety ratings are NOT lost or defaulted to safe!
      expect(analysis.ingredients.length, 3);
      expect(analysis.ingredients[0].category, SafetyCategory.safe);
      expect(
        analysis.ingredients[0].simpleExplanation,
        'Natural emulsifier to bind fat and cocoa.',
      );
      expect(
        analysis.ingredients[0].healthNote,
        'FSSAI Permitted Emulsifier',
      );

      expect(analysis.ingredients[1].category, SafetyCategory.moderate);
      expect(
        analysis.ingredients[1].simpleExplanation,
        'Refined vegetable lipid.',
      );

      expect(analysis.ingredients[2].category, SafetyCategory.avoid);
      expect(analysis.ingredients[2].simpleExplanation, 'Azo dye.');
      expect(
        analysis.ingredients[2].healthNote,
        'Restricted by FSSAI for infants.',
      );
    });

    test('handles untyped Map<dynamic, dynamic> safely without dropping items', () {
      final untypedJson = <dynamic, dynamic>{
        'food_name': 'Masala Chai',
        'source': 'street_food',
        'nutrients': <dynamic, dynamic>{
          'calories': 120.0,
          'protein_g': 3.5,
          'carbs_g': 18.0,
          'fat_g': 4.0,
        },
        'parsed_ingredients': <dynamic>[
          <dynamic, dynamic>{
            'name': 'Whole Milk',
            'safety': 'safe',
            'plain_explanation': 'Dairy liquid',
          },
          <dynamic, dynamic>{
            'name': 'Refined White Sugar',
            'safety': 'moderate',
            'plain_explanation': 'Added sucrose',
          },
        ],
      };

      final item = FoodItem.fromJson(Map<String, dynamic>.from(untypedJson));
      expect(item.parsedIngredients.length, 2);
      expect(item.parsedIngredients[0].name, 'Whole Milk');
      expect(item.parsedIngredients[1].safety, IngredientSafety.moderate);

      final analysis = FoodAnalysisResponse.fromJson(item.toJson());
      expect(analysis.ingredients.length, 2);
      expect(analysis.ingredients[1].category, SafetyCategory.moderate);
      expect(analysis.nutrients.protein100g, 3.5);
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
