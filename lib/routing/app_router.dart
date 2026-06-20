import 'dart:developer';

import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/organizations/presentation/pages/organizations_page.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isInitialized = authNotifier.isInitialized;
      final hasSession = authNotifier.session != null;
      final currentPath = state.matchedLocation;

      log('[GoRouter redirect] path=$currentPath, initialized=$isInitialized, hasSession=$hasSession');

      // Still waiting for the first auth event from Supabase — stay on splash.
      if (!isInitialized) {
        log('[GoRouter redirect] Not initialized → staying on splash');
        return currentPath == RouteNames.splash ? null : RouteNames.splash;
      }

      // Auth pages (splash, login, signup) that an authenticated user
      // should be redirected away from.
      final isAuthRoute = currentPath == RouteNames.splash ||
          currentPath == RouteNames.login ||
          currentPath == RouteNames.signup;

      if (hasSession && isAuthRoute) {
        log('[GoRouter redirect] Has session + on auth route → /organizations');
        return RouteNames.organizations;
      }

      if (!hasSession && !isAuthRoute) {
        log('[GoRouter redirect] No session + on protected route → /login');
        return RouteNames.login;
      }

      // If we're on splash but initialized with no session, go to login.
      if (currentPath == RouteNames.splash && !hasSession) {
        log('[GoRouter redirect] Splash + no session → /login');
        return RouteNames.login;
      }

      log('[GoRouter redirect] No redirect needed');
      return null; // No redirect needed.
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (_, _) => const SignupPage(),
      ),
      GoRoute(
        path: RouteNames.organizations,
        builder: (_, _) => const OrganizationsPage(),
      ),
    ],
  );
}
