import 'dart:developer';

import 'package:dev_collab/features/auth/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Session? get currentSession => _authService.currentSession;

  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    log('[AuthRepository] signIn called');
    final response = await _authService.signIn(
      email: email,
      password: password,
    );
    log('[AuthRepository] signIn completed — session: ${response.session != null}');
    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    log('[AuthRepository] signUp called');
    final response = await _authService.signUp(
      email: email,
      password: password,
    );
    log('[AuthRepository] signUp completed — session: ${response.session != null}');
    return response;
  }

  Future<void> signOut() async {
    log('[AuthRepository] signOut called');
    await _authService.signOut();
    log('[AuthRepository] signOut completed');
  }
}
