import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/food_log_model.dart';
import '../data/diary_repository.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => DiaryRepository(),
);

class DiaryState {
  final DateTime selectedDate;
  final bool isLoading;
  final List<FoodLogEntry> logs;
  final double dailyCalorieGoal;
  final double targetCarbsG;
  final double targetProteinG;
  final double targetFatG;
  final String? errorMessage;

  const DiaryState({
    required this.selectedDate,
    this.isLoading = false,
    this.logs = const [],
    this.dailyCalorieGoal = 2000,
    this.targetCarbsG = 250,
    this.targetProteinG = 60,
    this.targetFatG = 65,
    this.errorMessage,
  });

  double get totalCaloriesConsumed =>
      logs.fold(0, (sum, entry) => sum + entry.caloriesConsumed);

  double _macroTotal(String key) => logs.fold(0, (sum, entry) {
        final value = entry.consumedMacros[key];
        return sum + (value is num ? value.toDouble() : 0);
      });

  double get totalCarbsConsumed => _macroTotal('carbs_g');
  double get totalProteinConsumed => _macroTotal('protein_g');
  double get totalFatConsumed => _macroTotal('fat_g');

  DiaryState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    List<FoodLogEntry>? logs,
    double? dailyCalorieGoal,
    double? targetCarbsG,
    double? targetProteinG,
    double? targetFatG,
    String? errorMessage,
  }) =>
      DiaryState(
        selectedDate: selectedDate ?? this.selectedDate,
        isLoading: isLoading ?? this.isLoading,
        logs: logs ?? this.logs,
        dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
        targetCarbsG: targetCarbsG ?? this.targetCarbsG,
        targetProteinG: targetProteinG ?? this.targetProteinG,
        targetFatG: targetFatG ?? this.targetFatG,
        errorMessage: errorMessage,
      );
}

class DiaryController extends StateNotifier<DiaryState> {
  final DiaryRepository _repository;

  DiaryController(this._repository)
      : super(DiaryState(selectedDate: DateTime.now())) {
    loadLogsForDate(state.selectedDate);
  }

  Future<void> changeDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await loadLogsForDate(date);
  }

  Future<void> loadLogsForDate(DateTime date) async {
    state = state.copyWith(isLoading: true);
    try {
      final logs = await _repository.fetchLogsForDate(date);
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> addEntry({
    required String foodName,
    String? cacheId,
    required double servingQuantityG,
    required double caloriesConsumed,
    required Map<String, dynamic> consumedMacros,
    required MealCategoryType mealType,
  }) async {
    try {
      final entry = await _repository.logFood(
        foodName: foodName,
        cacheId: cacheId,
        servingQuantityG: servingQuantityG,
        caloriesConsumed: caloriesConsumed,
        consumedMacros: consumedMacros,
        mealType: mealType,
        loggedAt: state.selectedDate,
      );
      state = state.copyWith(logs: [...state.logs, entry]);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> removeEntry(String id) async {
    try {
      await _repository.deleteLog(id);
      state = state.copyWith(
        logs: state.logs.where((entry) => entry.id != id).toList(),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }
}

final diaryControllerProvider =
    StateNotifierProvider<DiaryController, DiaryState>(
  (ref) => DiaryController(ref.watch(diaryRepositoryProvider)),
);
