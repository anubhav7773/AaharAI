import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aahar_ai/core/models/food_models.dart';
import 'package:aahar_ai/core/models/enums.dart';
import 'package:aahar_ai/core/network/api_client.dart';
import 'package:aahar_ai/core/network/network_providers.dart';
import 'package:aahar_ai/features/street_food/presentation/street_food_controller.dart';

class MockApiClient extends ApiClient {
  MockApiClient()
      : super(dioOverride: Dio(BaseOptions(baseUrl: 'http://test')));

  @override
  Future<FoodItem> getStreetFoodAnalysis(String dishName) async => FoodItem(
        foodName: dishName,
        source: FoodSourceType.streetFood,
        nutrients: const NutrientProfile(
          calories: 280,
          proteinG: 6,
          carbsG: 45,
          fatG: 8,
        ),
        preparationInsights: 'Steamed preparation with low oil factor.',
      );
}

void main() {
  test('selecting a category updates filter state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(streetFoodControllerProvider.notifier).selectCategory(
          'tibetan',
        );

    expect(
      container.read(streetFoodControllerProvider).selectedCategory,
      'tibetan',
    );
  });

  test('fetching a dish stores the active analysis', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    final item = await container
        .read(streetFoodControllerProvider.notifier)
        .fetchDishAnalysis('Veg Steamed Momo');

    expect(item?.foodName, 'Veg Steamed Momo');
    expect(
      container.read(streetFoodControllerProvider).activeDishAnalysis,
      isNotNull,
    );
  });
}
