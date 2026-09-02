import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class MacroPillCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MacroPillCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildMetricCell(
          label: 'Calories',
          value: '${calories.toInt()}',
          unit: 'kcal',
          color: AaharTheme.calorieOrange,
        ),
        const SizedBox(width: 8),
        _buildMetricCell(
          label: 'Protein',
          value: protein.toStringAsFixed(1),
          unit: 'g',
          color: AaharTheme.proteinBlue,
        ),
        const SizedBox(width: 8),
        _buildMetricCell(
          label: 'Carbs',
          value: carbs.toStringAsFixed(1),
          unit: 'g',
          color: AaharTheme.carbsAmber,
        ),
        const SizedBox(width: 8),
        _buildMetricCell(
          label: 'Fat',
          value: fat.toStringAsFixed(1),
          unit: 'g',
          color: AaharTheme.fatPurple,
        ),
      ],
    );
  }

  Widget _buildMetricCell({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AaharTheme.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AaharTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
