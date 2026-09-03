import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/food_log_model.dart';
import '../../../../core/models/enums.dart';

class DiaryRepository {
  final SupabaseClient? _supabase;
  final List<FoodLogEntry> _localLogs = [];

  DiaryRepository({SupabaseClient? supabase}) : _supabase = supabase;

  SupabaseClient get _client {
    if (_supabase != null) return _supabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError('Supabase client not initialized');
    }
  }

  String? get _currentUserId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Convert local calendar day to UTC range [start, end)
  static (DateTime, DateTime) computeUtcDateRange(DateTime date) {
    final localStart = DateTime(date.year, date.month, date.day);
    final localEnd = localStart.add(const Duration(days: 1));
    return (localStart.toUtc(), localEnd.toUtc());
  }

  Future<List<FoodLogEntry>> fetchLogsForDate(DateTime date) async {
    final userId = _currentUserId;
    final (startUtc, endUtc) = computeUtcDateRange(date);
    final results = <FoodLogEntry>[];

    if (userId != null) {
      try {
        final response = await _client
            .from('food_logs')
            .select()
            .eq('user_id', userId)
            .gte('logged_at', startUtc.toIso8601String())
            .lt('logged_at', endUtc.toIso8601String())
            .order('logged_at');

        results.addAll(
          (response as List)
              .map((item) => FoodLogEntry.fromJson(item as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    final localForDate = _localLogs.where((entry) {
      final entryUtc = entry.loggedAt.toUtc();
      return (entryUtc.isAfter(startUtc) ||
              entryUtc.isAtSameMomentAs(startUtc)) &&
          entryUtc.isBefore(endUtc);
    });
    results.addAll(localForDate);

    results.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return results;
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
    if (userId != null) {
      try {
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
      } catch (_) {}
    }

    final entry = FoodLogEntry(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId ?? 'guest_user',
      cacheId: cacheId,
      foodName: foodName,
      servingQuantityG: servingQuantityG,
      caloriesConsumed: caloriesConsumed,
      consumedMacros: consumedMacros,
      mealType: mealType,
      loggedAt: loggedAt,
    );
    _localLogs.add(entry);
    return entry;
  }

  Future<void> deleteLog(String logId) async {
    _localLogs.removeWhere((item) => item.id == logId);
    if (_currentUserId != null) {
      try {
        await _client.from('food_logs').delete().eq('id', logId);
      } catch (_) {}
    }
  }
}
