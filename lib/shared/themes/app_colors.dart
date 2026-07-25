import 'package:flutter/material.dart';

extension AppColorsExt on BuildContext {
  Color get colorPrimary => Theme.of(this).colorScheme.primary;
  Color get colorOnPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get colorSecondary => Theme.of(this).colorScheme.secondary;
  Color get colorError => Theme.of(this).colorScheme.error;
  Color get colorSuccess => const Color(0xFF22C55E);
  Color get colorWarning => const Color(0xFFF59E0B);

  Color get colorBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get colorSurface => Theme.of(this).colorScheme.surface;
  Color get colorSurfaceLight => Theme.of(this).colorScheme.surfaceContainerHighest;
  Color get colorBorder => Theme.of(this).dividerTheme.color ?? const Color(0xFF262626);

  Color get colorTextPrimary => Theme.of(this).colorScheme.onSurface;
  Color get colorTextSecondary => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.7);
  Color get colorTextMuted => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.5);
}
