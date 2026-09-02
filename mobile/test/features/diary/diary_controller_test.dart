import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aahar_ai/core/models/enums.dart';
import 'package:aahar_ai/core/models/food_log_model.dart';
import 'package:aahar_ai/features/diary/data/diary_repository.dart';
import 'package:aahar_ai/features/diary/presentation/diary_controller.dart';

class FakeDiaryRepository extends DiaryRepository {
  final List<FoodLogEntry> entries;

  FakeDiaryRepository([this.entries = const []]);

  @override
  Future<List<FoodLogEntry>> fetchLogsForDate(DateTime date) async => entries;

  @override
  Future<FoodLogEntry> logFood({
    required String foodName,
    String? cacheId,
    required double servingQuantityG,
    required double caloriesConsumed,
    required Map<String, dynamic> consumedMacros,
    required MealCategoryType mealType,
    required DateTime loggedAt,
  }) async =>
      FoodLogEntry(
        id: 'new',
        userId: 'user',
        foodName: foodName,
        servingQuantityG: servingQuantityG,
        caloriesConsumed: caloriesConsumed,
        consumedMacros: consumedMacros,
        mealType: mealType,
        loggedAt: loggedAt,
      );
}

void main() {
  test('loads logs and computes macro totals', () async {
    final log = FoodLogEntry(
      id: '1',
      userId: 'user',
      foodName: 'Dal',
      servingQuantityG: 200,
      caloriesConsumed: 250,
      consumedMacros: const {
        'carbs_g': 30,
        'protein_g': 12,
        'fat_g': 5,
      },
      mealType: MealCategoryType.lunch,
      loggedAt: DateTime.now(),
    );
    final container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository([log])),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(diaryControllerProvider.notifier);
    await controller.loadLogsForDate(DateTime.now());
    final state = container.read(diaryControllerProvider);
    expect(state.totalCaloriesConsumed, 250);
    expect(state.totalProteinConsumed, 12);
  });

  test('adds a persisted entry to the timeline', () async {
    final container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(diaryControllerProvider.notifier);
    await controller.addEntry(
      foodName: 'Idli',
      servingQuantityG: 150,
      caloriesConsumed: 180,
      consumedMacros: const {'carbs_g': 35},
      mealType: MealCategoryType.breakfast,
    );
    expect(
        container.read(diaryControllerProvider).logs.single.foodName, 'Idli');
  });
}
