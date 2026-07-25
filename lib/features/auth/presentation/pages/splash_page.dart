
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

/// Splash screen shown while waiting for initial auth state.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.colorBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Image Placeholder — can be replaced with Image.asset('assets/logo.png') later
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/images/dark_mode_icon.png'
                  : 'assets/images/light_mode_icon.png',
              width: 100,
              height: 100,
            ),
            SizedBox(height: 28),
            Text(
              'DevCollab',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.colorTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Initializing workspace...',
              style: TextStyle(
                fontSize: 14,
                color: context.colorTextSecondary,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.colorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
