import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/food_log_model.dart';
import '../../../core/theme/app_theme.dart';
import 'diary_controller.dart';
import 'widgets/diary_banner_ad.dart';

class DailyDiaryScreen extends ConsumerStatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  ConsumerState<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends ConsumerState<DailyDiaryScreen> {
  static const _mealCategories = [
    (MealCategoryType.breakfast, 'Breakfast'),
    (MealCategoryType.lunch, 'Lunch'),
    (MealCategoryType.snack, 'Snacks'),
    (MealCategoryType.dinner, 'Dinner'),
  ];

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryControllerProvider);
    ref.listen(diaryControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final selectedDate = diaryState.selectedDate;

    return Scaffold(
      backgroundColor: AaharTheme.scaffoldBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                final date = selectedDate.subtract(const Duration(days: 1));
                ref.read(diaryControllerProvider.notifier).changeDate(date);
              },
            ),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AaharTheme.textHeadline,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, d MMM').format(selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AaharTheme.textHeadline,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                final date = selectedDate.add(const Duration(days: 1));
                ref.read(diaryControllerProvider.notifier).changeDate(date);
              },
            ),
          ],
        ),
      ),
      body: diaryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Card 1: Dynamic Calorie Budget & Macros
                _buildCalorieBudgetCard(diaryState),

                const SizedBox(height: 16),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meal Logs Timeline',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AaharTheme.textHeadline,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/scanner'),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Scan Food'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dynamic Meal Logs List
                ..._mealCategories.map(
                  (cat) => _buildMealSection(
                    categoryType: cat.$1,
                    categoryTitle: cat.$2,
                    logs: diaryState.logs
                        .where((log) => log.mealType == cat.$1)
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Non-Intrusive AdMob Banner Container
                const DiaryBannerAd(),
              ],
            ),
    );
  }

  Widget _buildCalorieBudgetCard(DiaryState diaryState) {
    final consumed = diaryState.totalCaloriesConsumed.toInt();
    final target = diaryState.dailyCalorieGoal.toInt();
    final remaining = target - consumed;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AaharTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$consumed',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AaharTheme.textHeadline,
                        ),
                      ),
                      Text(
                        ' / $target kcal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AaharTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining >= 0
                        ? '$remaining kcal remaining'
                        : '${remaining.abs()} kcal over budget',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0
                          ? AaharTheme.safeGreen
                          : AaharTheme.avoidRed,
                    ),
                  ),
                ],
              ),
              // Mini Radial Ring
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor:
                          AaharTheme.borderGrey.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AaharTheme.primaryGreen,
                      ),
                      strokeWidth: 6,
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AaharTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AaharTheme.borderGrey),
          const SizedBox(height: 16),

          // Real Macro Progress Bars
          _buildMacroProgressBar(
            label: 'Carbs',
            current: diaryState.totalCarbsConsumed,
            target: diaryState.targetCarbsG,
            unit: 'g',
            color: AaharTheme.carbsAmber,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressBar(
            label: 'Protein',
            current: diaryState.totalProteinConsumed,
            target: diaryState.targetProteinG,
            unit: 'g',
            color: AaharTheme.proteinBlue,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressBar(
            label: 'Fat',
            current: diaryState.totalFatConsumed,
            target: diaryState.targetFatG,
            unit: 'g',
            color: AaharTheme.fatPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AaharTheme.textHeadline,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)}$unit / ${target.toInt()}$unit',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AaharTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AaharTheme.borderGrey.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection({
    required MealCategoryType categoryType,
    required String categoryTitle,
    required List<FoodLogEntry> logs,
  }) {
    final mealCalories = logs.fold<double>(
      0.0,
      (sum, item) => sum + item.caloriesConsumed,
    ).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AaharTheme.borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      categoryTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AaharTheme.textHeadline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AaharTheme.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$mealCalories kcal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AaharTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AaharTheme.primaryGreen,
                    size: 20,
                  ),
                  onPressed: () => context.go('/scanner'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'No items logged for $categoryTitle',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AaharTheme.textLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...logs.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AaharTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodName,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AaharTheme.textBody,
                              ),
                            ),
                            Text(
                              '${item.servingQuantityG.toInt()}g • ${DateFormat('h:mm a').format(item.loggedAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AaharTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.caloriesConsumed.toInt()} kcal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AaharTheme.textMuted,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AaharTheme.avoidRed,
                        ),
                        onPressed: () {
                          ref
                              .read(diaryControllerProvider.notifier)
                              .removeEntry(item.id);
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
