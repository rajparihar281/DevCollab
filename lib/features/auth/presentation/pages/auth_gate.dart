import 'dart:developer';

import 'package:dev_collab/features/auth/presentation/pages/login_page.dart';
import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AuthGate listens to the Supabase auth state stream via Riverpod and
/// reactively switches between the login screen and the home screen.
///
/// **Previous bug**: This was a StatelessWidget that called
/// `Supabase.instance.client.auth.currentUser` once — a one-shot read
/// that never re-evaluated after login/logout. The widget never rebuilt,
/// so the user was stuck on the login page even after a successful sign-in.
///
/// **Fix**: Converted to a ConsumerWidget that `watch`es the
/// `authStateProvider` (a StreamProvider over `onAuthStateChange`).
/// Every auth event now triggers a rebuild.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    log('[AuthGate] build() called');

    return authState.when(
      data: (state) {
        log('[AuthGate] Auth event: ${state.event}');
        log('[AuthGate] Session: ${state.session != null ? "EXISTS" : "NULL"}');

        if (state.session != null) {
          log('[AuthGate] → Showing HOME for user: ${state.session!.user.email}');
          return Scaffold(
            appBar: AppBar(
              title: const Text('DevCollab'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: () {
                    log('[AuthGate] Sign-out button pressed');
                    ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),
            body: Center(
              child: Text('Welcome ${state.session!.user.email}'),
            ),
          );
        }

        log('[AuthGate] → Showing LOGIN (no session)');
        return const LoginPage();
      },
      loading: () {
        log('[AuthGate] → Loading auth state...');
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stack) {
        log('[AuthGate] ERROR: $error');
        log('[AuthGate] STACK: $stack');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Auth Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
