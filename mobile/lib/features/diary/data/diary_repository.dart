import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/food_log_model.dart';
import '../../../../core/models/enums.dart';

class DiaryRepository {
  final SupabaseClient? _supabase;

  DiaryRepository({SupabaseClient? supabase}) : _supabase = supabase;

  SupabaseClient get _client => _supabase ?? Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Convert local calendar day to UTC range [start, end)
  static (DateTime, DateTime) computeUtcDateRange(DateTime date) {
    final localStart = DateTime(date.year, date.month, date.day);
    final localEnd = localStart.add(const Duration(days: 1));
    return (localStart.toUtc(), localEnd.toUtc());
  }

  Future<List<FoodLogEntry>> fetchLogsForDate(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final (startUtc, endUtc) = computeUtcDateRange(date);
    try {
      final response = await _client
          .from('food_logs')
          .select()
          .eq('user_id', userId)
          .gte('logged_at', startUtc.toIso8601String())
          .lt('logged_at', endUtc.toIso8601String())
          .order('logged_at');

      return (response as List)
          .map((item) => FoodLogEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<FoodLogEntry> logFood({
    required String foodName,
    String? cacheId,
    required double servingQuantityG,
    required double caloriesConsumed,
    required Map<String, dynamic> consumedMacros,
    required MealCategoryType mealType,
    required DateTime loggedAt,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('User not authenticated');
    }

    final response = await _client
        .from('food_logs')
        .insert({
          'user_id': userId,
          'cache_id': cacheId,
          'food_name': foodName,
          'serving_quantity_g': servingQuantityG,
          'calories_consumed': caloriesConsumed,
          'consumed_macros': consumedMacros,
          'meal_type': mealType.toValue(),
          'logged_at': loggedAt.toIso8601String(),
        })
        .select()
        .single();

    return FoodLogEntry.fromJson(response);
  }

  Future<void> deleteLog(String logId) async {
    await _client.from('food_logs').delete().eq('id', logId);
  }
}
