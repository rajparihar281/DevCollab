import 'dart:developer';

import 'package:flutter/material.dart';

/// Splash screen shown while waiting for the initial auth state from Supabase.
///
/// Navigation away from this screen is handled entirely by GoRouter's
/// `redirect` function — once [AuthNotifier.isInitialized] becomes true,
/// the router redirects to either `/login` or `/organizations`.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    log('[SplashPage] build() — waiting for auth initialization...');
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
