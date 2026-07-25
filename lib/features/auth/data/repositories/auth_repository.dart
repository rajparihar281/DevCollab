import 'dart:io';

import 'package:dev_collab/features/auth/data/services/auth_service.dart';
import 'package:dev_collab/features/auth/domain/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  User? get currentUser => _authService.currentUser;

  Session? get currentSession => _authService.currentSession;

  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<Profile?> getProfile(String userId) async {
    final data = await _authService.getProfile(userId);
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _authService.updateProfile(userId, updates);
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    return _authService.uploadProfilePicture(file, userId);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {

    final response = await _authService.signIn(
      email: email,
      password: password,
    );

    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {

    final response = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    return response;
  }

  Future<AuthResponse> signInWithGoogle(String webClientId) async {

    final response = await _authService.signInWithGoogle(webClientId);

    return response;
  }

  Future<void> signOut() async {

    await _authService.signOut();

  }
}
