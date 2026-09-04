/// Public, compile-time configuration supplied with `--dart-define`.
class AppEnv {
  static const _defaultApiBaseUrl = 'https://aaharai-u72j.onrender.com';
  static const _defaultSupabaseUrl = 'https://ptrmqerwjagggardjdqh.supabase.co';
  static const _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0cm1xZXJ3amFnZ2dhcmRqZHFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzNDY0MjgsImV4cCI6MjEwMzkyMjQyOH0.yB3pHZkMUR3FCORjmDJJH9HsUtB61tQEdRC6jtpqx2k';
  static const _defaultPrivacyPolicyUrl =
      'https://asiverticals.me/aaharai/privacy';

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String privacyPolicyUrl;

  const AppEnv({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.privacyPolicyUrl = _defaultPrivacyPolicyUrl,
  });

  const AppEnv.forTesting({
    required String apiBaseUrl,
    required String supabaseUrl,
    required String supabaseAnonKey,
    String privacyPolicyUrl = _defaultPrivacyPolicyUrl,
  }) : this(
          apiBaseUrl: apiBaseUrl,
          supabaseUrl: supabaseUrl,
          supabaseAnonKey: supabaseAnonKey,
          privacyPolicyUrl: privacyPolicyUrl,
        );

  static AppEnv fromEnvironment() => const AppEnv(
        apiBaseUrl: String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: _defaultApiBaseUrl,
        ),
        supabaseUrl: String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: _defaultSupabaseUrl,
        ),
        supabaseAnonKey: String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: _defaultSupabaseAnonKey,
        ),
        privacyPolicyUrl: String.fromEnvironment(
          'PRIVACY_POLICY_URL',
          defaultValue: _defaultPrivacyPolicyUrl,
        ),
      );

  AppEnv validate() {
    if (apiBaseUrl.trim().isEmpty) {
      throw const FormatException('API_BASE_URL must not be empty');
    }
    final apiUri = Uri.tryParse(apiBaseUrl);
    if (apiUri == null ||
        !{'http', 'https'}.contains(apiUri.scheme) ||
        apiUri.host.isEmpty) {
      throw const FormatException(
        'API_BASE_URL must be a valid HTTP or HTTPS URL',
      );
    }
    if (supabaseUrl.trim().isEmpty) {
      throw const FormatException('SUPABASE_URL must not be empty');
    }
    final supabaseUri = Uri.tryParse(supabaseUrl);
    if (supabaseUri == null ||
        supabaseUri.scheme != 'https' ||
        supabaseUri.host.isEmpty) {
      throw const FormatException(
        'SUPABASE_URL must be a valid HTTPS URL',
      );
    }
    if (supabaseAnonKey.trim().isEmpty) {
      throw const FormatException('SUPABASE_ANON_KEY must not be empty');
    }
    return this;
  }
}
