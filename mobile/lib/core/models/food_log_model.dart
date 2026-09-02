import 'enums.dart';

class FoodLogEntry {
  final String id;
  final String userId;
  final String? cacheId;
  final String foodName;
  final double servingQuantityG;
  final double caloriesConsumed;
  final Map<String, dynamic> consumedMacros;
  final MealCategoryType mealType;
  final DateTime loggedAt;

  const FoodLogEntry({
    required this.id,
    required this.userId,
    this.cacheId,
    required this.foodName,
    required this.servingQuantityG,
    required this.caloriesConsumed,
    required this.consumedMacros,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    final macros = json['consumed_macros'];
    return FoodLogEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cacheId: json['cache_id'] as String?,
      foodName: json['food_name'] as String,
      servingQuantityG: (json['serving_quantity_g'] as num).toDouble(),
      caloriesConsumed: (json['calories_consumed'] as num).toDouble(),
      consumedMacros:
          macros is Map<String, dynamic> ? macros : <String, dynamic>{},
      mealType: MealCategoryType.fromString(json['meal_type'] as String?),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'cache_id': cacheId,
        'food_name': foodName,
        'serving_quantity_g': servingQuantityG,
        'calories_consumed': caloriesConsumed,
        'consumed_macros': consumedMacros,
        'meal_type': mealType.toValue(),
        'logged_at': loggedAt.toIso8601String(),
      };
}
