import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum IngredientSafety {
  safe,
  moderate,
  avoid;

  static IngredientSafety fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'avoid':
        return IngredientSafety.avoid;
      case 'moderate':
        return IngredientSafety.moderate;
      case 'safe':
      default:
        return IngredientSafety.safe;
    }
  }

  String get label {
    switch (this) {
      case IngredientSafety.safe:
        return 'Safe';
      case IngredientSafety.moderate:
        return 'Moderate';
      case IngredientSafety.avoid:
        return 'Avoid';
    }
  }

  Color get textColor {
    switch (this) {
      case IngredientSafety.safe:
        return AaharTheme.safeGreen;
      case IngredientSafety.moderate:
        return AaharTheme.moderateAmber;
      case IngredientSafety.avoid:
        return AaharTheme.avoidRed;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case IngredientSafety.safe:
        return AaharTheme.safeGreenBg;
      case IngredientSafety.moderate:
        return AaharTheme.moderateAmberBg;
      case IngredientSafety.avoid:
        return AaharTheme.avoidRedBg;
    }
  }
}

class SafetyBadge extends StatelessWidget {
  final IngredientSafety safety;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SafetyBadge({
    super.key,
    required this.safety,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: safety.backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        safety.label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: safety.textColor,
        ),
      ),
    );
  }
}
