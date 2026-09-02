/// Public, compile-time configuration supplied with `--dart-define`.
class AppEnv {
  static const _defaultApiBaseUrl = 'http://10.0.2.2:8000';

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String privacyPolicyUrl;

  const AppEnv({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.privacyPolicyUrl = 'https://asiverticals.me/aaharai/privacy',
  });

  const AppEnv.forTesting({
    required String apiBaseUrl,
    required String supabaseUrl,
    required String supabaseAnonKey,
    String privacyPolicyUrl = 'https://asiverticals.me/aaharai/privacy',
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
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        privacyPolicyUrl: String.fromEnvironment(
          'PRIVACY_POLICY_URL',
          defaultValue: 'https://asiverticals.me/aaharai/privacy',
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
