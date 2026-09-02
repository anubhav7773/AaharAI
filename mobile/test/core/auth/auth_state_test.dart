import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aahar_ai/core/auth/auth_service.dart';
import 'package:aahar_ai/core/auth/auth_state_provider.dart';

class MockAuthService extends AuthService {
  bool googleCalled = false;
  bool guestCalled = false;

  @override
  Future<AuthResponse> signInWithGoogle() async {
    googleCalled = true;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signInAsGuest() async {
    guestCalled = true;
    return AuthResponse();
  }
}

void main() {
  test('AuthController triggers Google Sign-In and resets loading', () async {
    final mock = MockAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(mock)],
    );
    expect(container.read(authLoadingProvider), isFalse);
    expect(
      await container.read(authControllerProvider.notifier).signInWithGoogle(),
      isTrue,
    );
    expect(mock.googleCalled, isTrue);
    expect(container.read(authLoadingProvider), isFalse);
    container.dispose();
  });

  test('AuthController triggers guest mode', () async {
    final mock = MockAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(mock)],
    );
    expect(
      await container.read(authControllerProvider.notifier).signInAsGuest(),
      isTrue,
    );
    expect(mock.guestCalled, isTrue);
    container.dispose();
  });
}
