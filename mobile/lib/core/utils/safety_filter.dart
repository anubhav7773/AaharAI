/// Google Play Health & Wellness Compliance Interceptor (Doc_10)
/// Prevents non-compliant medical claims or blacklisted keywords from reaching the UI.
class HealthClaimFilter {
  static final RegExp _prohibitedRegex = RegExp(
    r'\b(cure|cures|curing|treat|treatment|treating|prevent disease|prevents disease|reverses disease|increase lifespan|prolong life|clinical therapy)\b',
    caseSensitive: false,
  );

  /// Inspects any raw text from Gemini and replaces non-compliant words with neutral educational phrasing
  static String sanitizeResponse(String rawText) {
    return rawText.replaceAllMapped(_prohibitedRegex, (match) {
      final matchedWord = match.group(0)?.toLowerCase();
      switch (matchedWord) {
        case 'cure':
        case 'cures':
          return 'manage dietary intake';
        case 'treat':
        case 'treatment':
          return 'nutritional awareness';
        case 'prevent disease':
          return 'support dietary balance';
        case 'increase lifespan':
          return 'support overall well-being';
        default:
          return 'informed food choices';
      }
    });
  }

  /// Mandatory Google Play Non-Medical Disclaimer
  static const String nonMedicalDisclaimer =
      'AaharAi provides educational food awareness and nutrition transparency. It is not a medical device and does not diagnose, treat, cure, or prevent any medical condition.';

  /// Mandatory Physician Consultation Reminder
  static const String physicianConsultationDisclaimer =
      'Always consult a qualified physician or certified healthcare professional before making significant dietary changes.';
}
