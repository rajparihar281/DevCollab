import 'dart:async';

import 'package:dev_collab/core/supabase/supabase_provider.dart';
import 'package:dev_collab/features/auth/data/repositories/auth_repository.dart';
import 'package:dev_collab/features/auth/data/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Service & Repository (unchanged) ────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
});

// ─── Auth State Stream (kept for widgets that need reactive auth) ────

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.authStateChanges.map((authState) {


    if (authState.session != null) {

    }
    return authState;
  });
});

// ─── GoRouter Auth Notifier ─────────────────────────────────────────
/// A [ChangeNotifier] that subscribes to Supabase's auth stream and calls
/// [notifyListeners] on every auth event. This is plugged into GoRouter's
/// [refreshListenable] so the router re-evaluates its `redirect` function
/// every time the auth state changes.

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._repository) {
    _init();
  }

  final AuthRepository _repository;

  Session? _session;
  Session? get session => _session;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late final StreamSubscription<AuthState> _subscription;

  void _init() {
    // Seed with the current session (may be null).
    _session = _repository.currentSession;


    _subscription = _repository.authStateChanges.listen(
      (authState) {


        if (authState.session != null) {

        }

        _session = authState.session;
        _isInitialized = true;
        notifyListeners(); // ← Triggers GoRouter redirect re-evaluation
      },
      onError: (error, stack) {


        _isInitialized = true;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Singleton [AuthNotifier] provider — lives for the entire app lifetime.
final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repository);

  ref.onDispose(() => notifier.dispose());

  return notifier;
});
