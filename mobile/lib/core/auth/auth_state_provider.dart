import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map(
        (event) => event.session?.user,
      );
});

final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthController(this._authService, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> signInWithGoogle() async {
    return _run(() => _authService.signInWithGoogle());
  }

  Future<bool> signInAsGuest() async {
    return _run(() => _authService.signInAsGuest());
  }

  Future<void> signOut() => _authService.signOut();

  Future<bool> _run(Future<Object?> Function() action) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authServiceProvider), ref);
});
