import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient? _client;
  final GoogleSignIn _googleSignIn;

  AuthService({SupabaseClient? client, GoogleSignIn? googleSignIn})
      : _client = client,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated {
    final user = _supabase.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google Sign-In was cancelled by the user.');
      }
      final authentication = await googleUser.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
            'Missing Google ID Token from authentication provider.');
      }
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authentication.accessToken,
      );
    } catch (error) {
      debugPrint('Google Sign-In Failure: $error');
      rethrow;
    }
  }

  Future<AuthResponse?> signInAsGuest() async {
    try {
      return await _supabase.auth.signInAnonymously();
    } on AuthApiException catch (error) {
      debugPrint(
        'Supabase anonymous sign-in unavailable (${error.code}): ${error.message}',
      );
      // Fallback: Return null so caller can proceed in guest exploration mode
      return null;
    } catch (error) {
      debugPrint('Guest Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _supabase.auth.signOut()]);
  }
}
