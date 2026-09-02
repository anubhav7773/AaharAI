import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aahar_ai/features/analysis/presentation/food_analysis_screen.dart';
import 'package:aahar_ai/features/analysis/models/food_analysis_model.dart';

void main() {
  testWidgets(
    'FoodAnalysisScreen displays product, macros, allergens, and molecule safety',
    (tester) async {
      final food = FoodAnalysisResponse(
        foodName: 'Almond Dark Chocolate',
        brandName: 'Amul',
        source: 'open_food_facts',
        nutrients: NutrientProfile(
          calories100g: 540,
          protein100g: 8.5,
          carbs100g: 48,
          fat100g: 35,
        ),
        allergensDetected: const ['Tree Nuts', 'Milk'],
        ingredients: [
          IngredientItem(
            name: 'Soy Lecithin',
            simpleExplanation: 'Keeps chocolate smooth.',
            category: SafetyCategory.safe,
            healthNote: 'Permitted emulsifier.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: FoodAnalysisScreen(analysis: food)),
      );

      expect(find.text('Almond Dark Chocolate'), findsOneWidget);
      expect(find.text('Amul'), findsOneWidget);
      expect(find.text('540'), findsOneWidget);
      expect(find.text('Contains: Tree Nuts, Milk'), findsOneWidget);
      expect(find.text('Soy Lecithin'), findsOneWidget);
      expect(find.text('Safe'), findsOneWidget);
      expect(find.text('Log to Daily Food Diary'), findsOneWidget);

      await tester.tap(find.text('Soy Lecithin'));
      await tester.pump();
      expect(find.text('Permitted emulsifier.'), findsOneWidget);
    },
  );
}
