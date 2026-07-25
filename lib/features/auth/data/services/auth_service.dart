import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart' as gsign;
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


    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );






      return response;
    } catch (e) {


      rethrow;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {


    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName}
            : null,
      );





      return response;
    } catch (e) {


      rethrow;
    }
  }

  Future<AuthResponse> signInWithGoogle(String webClientId) async {

    try {
      await gsign.GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );
      final googleUser = await gsign.GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;


      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      

      return response;
    } catch (e) {


      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {

      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    final fileExt = file.path.split('.').last;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    const bucketName = 'profile pics';

    try {
      await _client.storage.from(bucketName).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    } catch (e) {

      final errStr = e.toString();
      if (errStr.contains('403') ||
          errStr.contains('row-level security') ||
          errStr.contains('Unauthorized')) {
        throw Exception(
          'Storage RLS Policy Violation (403): Please run the SQL migration in supabase/migrations/20260710000002_add_storage_bucket_policies.sql to allow uploads to bucket "$bucketName".',
        );
      }
      rethrow;
    }

    return _client.storage.from(bucketName).getPublicUrl(fileName);
  }

  Future<void> signOut() async {


    try {
      await _client.auth.signOut();
      
      // Clear Google Sign-In state to prevent auto-login of the same user
      try {
        await gsign.GoogleSignIn.instance.disconnect();
      } catch (_) {}
      try {
        await gsign.GoogleSignIn.instance.signOut();
      } catch (_) {}
      

    } catch (e) {


      rethrow;
    }
  }
}
