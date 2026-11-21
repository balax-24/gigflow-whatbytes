import 'package:flutter/material.dart';

/// Type scale from Spec 03 §3.
abstract final class AppTypography {
  static TextTheme apply(TextTheme base) => base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    ),
  );
}
