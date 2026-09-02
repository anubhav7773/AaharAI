import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AaharTheme {
  // Exact Stitch Tokens (from design_assets/tokens/design_tokens.json)
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryDark = Color(0xFF00450D);
  static const Color primarySurface = Color(0xFFE8F5E9);
  static const Color scaffoldBg = Color(0xFFF8FAF9);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF2F4F3);
  static const Color surfaceContainer = Color(0xFFECEEED);
  static const Color surfaceHigh = Color(0xFFE6E9E8);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFC0C9BB);

  // Text Tokens
  static const Color textHeadline = Color(0xFF111827);
  static const Color onSurface = Color(0xFF191C1C);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Semantic Safety Colors (FSSAI Categorization)
  static const Color safeGreen = Color(0xFF16A34A);
  static const Color safeGreenBg = Color(0xFFDCFCE7);
  static const Color moderateAmber = Color(0xFFD97706);
  static const Color moderateAmberBg = Color(0xFFFEF3C7);
  static const Color avoidRed = Color(0xFFDC2626);
  static const Color avoidRedBg = Color(0xFFFEE2E2);

  // Macro Nutrient Indicators
  static const Color calorieOrange = Color(0xFFEA580C);
  static const Color proteinBlue = Color(0xFF0284C7);
  static const Color carbsAmber = Color(0xFFF59E0B);
  static const Color fatPurple = Color(0xFF8B5CF6);

  static ThemeData get lightTheme {
    final baseFontTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: cardWhite,
        surfaceTint: primarySurface,
        outlineVariant: outlineVariant,
      ),
      textTheme: baseFontTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: textHeadline,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: textHeadline,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textHeadline,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textBody,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textBody,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textHeadline,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: const BorderSide(color: borderGrey, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textHeadline),
        titleTextStyle: GoogleFonts.inter(
          color: textHeadline,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardWhite,
        indicatorColor: primarySurface,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
    );
  }
}
