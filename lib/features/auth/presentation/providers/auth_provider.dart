import 'dart:developer';

import 'package:dev_collab/core/supabase/supabase_provider.dart';
import 'package:dev_collab/features/auth/data/repositories/auth_repository.dart';
import 'package:dev_collab/features/auth/data/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.authStateChanges.map((authState) {
    log('[authStateProvider] Auth event: ${authState.event}');
    log('[authStateProvider] Session: ${authState.session != null ? "EXISTS" : "NULL"}');
    if (authState.session != null) {
      log('[authStateProvider] User: ${authState.session!.user.email}');
    }
    return authState;
  });
});
