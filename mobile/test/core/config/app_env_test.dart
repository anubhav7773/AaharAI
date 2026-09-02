import 'package:flutter_test/flutter_test.dart';
import 'package:aahar_ai/core/config/app_env.dart';

void main() {
  AppEnv validEnv() => const AppEnv.forTesting(
        apiBaseUrl: 'http://10.0.2.2:8000',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'public-anon-key',
      );

  test('accepts explicit valid public configuration', () {
    final env = validEnv().validate();

    expect(env.apiBaseUrl, 'http://10.0.2.2:8000');
    expect(env.supabaseUrl, 'https://project.supabase.co');
    expect(env.supabaseAnonKey, 'public-anon-key');
  });

  test('rejects missing public values with variable names', () {
    expect(
      () => const AppEnv.forTesting(
        apiBaseUrl: 'http://10.0.2.2:8000',
        supabaseUrl: '',
        supabaseAnonKey: 'secret-value-that-must-not-appear',
      ).validate(),
      throwsA(
        predicate<FormatException>(
          (error) =>
              error.message.contains('SUPABASE_URL') &&
              !error.message.contains('secret-value'),
        ),
      ),
    );
  });

  test('rejects malformed API URLs without echoing the supplied value', () {
    expect(
      () => const AppEnv.forTesting(
        apiBaseUrl: 'ftp://private.example.invalid',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'public-anon-key',
      ).validate(),
      throwsA(
        predicate<FormatException>(
          (error) => error.message.contains('API_BASE_URL'),
        ),
      ),
    );
  });

  test('local emulator default still requires public Supabase defines', () {
    expect(
      () => const AppEnv.forTesting(
        apiBaseUrl: 'http://10.0.2.2:8000',
        supabaseUrl: '',
        supabaseAnonKey: '',
      ).validate(),
      throwsA(
        predicate<FormatException>(
          (error) => error.message.contains('SUPABASE_URL'),
        ),
      ),
    );
  });
}
