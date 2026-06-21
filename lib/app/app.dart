import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../shared/themes/app_theme.dart';

/// Provider that creates the GoRouter instance wired to auth state.
/// Using a Provider ensures the router is created once and reused.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  log('[appRouterProvider] Creating GoRouter with AuthNotifier');
  return createAppRouter(authNotifier);
});

class DevCollabApp extends ConsumerWidget {
  const DevCollabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    log('[DevCollabApp] build() called');

    return MaterialApp.router(
      title: 'DevCollab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
