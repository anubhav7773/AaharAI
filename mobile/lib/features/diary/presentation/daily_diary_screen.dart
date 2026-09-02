import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class DailyDiaryScreen extends StatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  State<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends State<DailyDiaryScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _meals = [
    {
      'mealType': 'Breakfast',
      'items': [
        {'name': '2 Whole Wheat Roti + Dal', 'calories': 310, 'time': '8:30 AM'},
        {'name': 'Masala Chai (with 1 tsp sugar)', 'calories': 75, 'time': '8:45 AM'},
      ],
    },
    {
      'mealType': 'Lunch',
      'items': [
        {'name': 'Steamed Rice + Paneer Curry + Salad', 'calories': 560, 'time': '1:15 PM'},
      ],
    },
    {
      'mealType': 'Snacks',
      'items': [
        {'name': 'Marie Gold Biscuits (Scanned)', 'calories': 135, 'time': '4:45 PM'},
        {'name': 'Roasted Makhana (Foxnuts)', 'calories': 95, 'time': '5:00 PM'},
      ],
    },
    {
      'mealType': 'Dinner',
      'items': [
        {'name': 'Veg Steamed Momos (6 pcs)', 'calories': 245, 'time': '8:15 PM'},
      ],
    },
  ];

  int get _totalCaloriesConsumed {
    int total = 0;
    for (final meal in _meals) {
      final items = meal['items'] as List<Map<String, dynamic>>;
      for (final item in items) {
        total += (item['calories'] as num).toInt();
      }
    }
    return total;
  }

  static const int _targetCalories = 2000;

  @override
  Widget build(BuildContext context) {
    final remainingCalories = _targetCalories - _totalCaloriesConsumed;

    return Scaffold(
      backgroundColor: AaharTheme.scaffoldBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1));
                });
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
                  'Today, ${_selectedDate.day} Sep',
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
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Card 1: Calorie Budget Progress Card
          _buildCalorieBudgetCard(remainingCalories),

          const SizedBox(height: 16),

          // Section Title
          Text(
            'Meal Logs Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AaharTheme.textHeadline,
            ),
          ),

          const SizedBox(height: 12),

          // Meal Logs List
          ..._meals.map((meal) => _buildMealSection(meal)),

          const SizedBox(height: 20),

          // Card 3: Non-Intrusive AdMob Banner Container
          _buildAdMobBannerSlot(),
        ],
      ),
    );
  }

  Widget _buildCalorieBudgetCard(int remainingCalories) {
    final progress = (_totalCaloriesConsumed / _targetCalories).clamp(0.0, 1.0);

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
                        '$_totalCaloriesConsumed',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AaharTheme.textHeadline,
                        ),
                      ),
                      Text(
                        ' / $_targetCalories kcal',
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
                    remainingCalories >= 0
                        ? '$remainingCalories kcal remaining'
                        : '${remainingCalories.abs()} kcal over budget',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remainingCalories >= 0
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
                      backgroundColor: AaharTheme.borderGrey.withValues(alpha: 0.5),
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

          // Macro Progress Bars
          _buildMacroProgressBar(
            label: 'Carbs',
            current: 180,
            target: 250,
            unit: 'g',
            color: AaharTheme.carbsAmber,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressBar(
            label: 'Protein',
            current: 48,
            target: 60,
            unit: 'g',
            color: AaharTheme.proteinBlue,
          ),
          const SizedBox(height: 10),
          _buildMacroProgressBar(
            label: 'Fat',
            current: 42,
            target: 65,
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
    final progress = (current / target).clamp(0.0, 1.0);

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
              '${current.toInt()}$unit / ${target.toInt()}$unit',
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

  Widget _buildMealSection(Map<String, dynamic> meal) {
    final mealType = meal['mealType'] as String;
    final items = meal['items'] as List<Map<String, dynamic>>;

    int mealCalories = 0;
    for (final item in items) {
      mealCalories += (item['calories'] as num).toInt();
    }

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
                      mealType,
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Add food item to $mealType')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No items logged yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AaharTheme.textLight,
                  ),
                ),
              )
            else
              ...items.map((item) {
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
                        child: Text(
                          item['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AaharTheme.textBody,
                          ),
                        ),
                      ),
                      Text(
                        '${item['calories']} kcal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AaharTheme.textMuted,
                        ),
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

  Widget _buildAdMobBannerSlot() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AaharTheme.borderGrey),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AaharTheme.textLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SPONSORED',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AaharTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AdMob 320x50 Banner Space',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AaharTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
