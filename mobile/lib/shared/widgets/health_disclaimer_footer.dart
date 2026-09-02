import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class HealthDisclaimerFooter extends StatelessWidget {
  final String? customText;

  const HealthDisclaimerFooter({
    super.key,
    this.customText,
  });

  static const String defaultDisclaimer =
      'AaharAi provides general food education. It is not a medical device and does not diagnose, treat, or cure diseases.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Text(
        customText ?? defaultDisclaimer,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          height: 1.4,
          color: AaharTheme.textLight,
        ),
      ),
    );
  }
}
