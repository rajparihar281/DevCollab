import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    log('[AuthService] signIn called with email: $email');

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      log('[AuthService] signIn response received');
      log('[AuthService] session: ${response.session != null ? "EXISTS" : "NULL"}');
      log('[AuthService] user: ${response.user?.email ?? "NULL"}');
      log('[AuthService] accessToken: ${response.session?.accessToken != null ? "EXISTS (${response.session!.accessToken.length} chars)" : "NULL"}');

      return response;
    } catch (e, st) {
      log('[AuthService] signIn ERROR: $e');
      log('[AuthService] signIn STACK: $st');
      rethrow;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    log('[AuthService] signUp called with email: $email');

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      log('[AuthService] signUp response received');
      log('[AuthService] session: ${response.session != null ? "EXISTS" : "NULL"}');
      log('[AuthService] user: ${response.user?.email ?? "NULL"}');

      return response;
    } catch (e, st) {
      log('[AuthService] signUp ERROR: $e');
      log('[AuthService] signUp STACK: $st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    log('[AuthService] signOut called');

    try {
      await _client.auth.signOut();
      log('[AuthService] signOut successful');
    } catch (e, st) {
      log('[AuthService] signOut ERROR: $e');
      log('[AuthService] signOut STACK: $st');
      rethrow;
    }
  }
}
