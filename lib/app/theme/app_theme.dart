import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/app_colors.dart';
import 'package:gigflow/app/theme/app_typography.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';

abstract final class AppTheme {
  static ThemeData dark() => _base(
    ColorScheme.fromSeed(
      seedColor: AppColors.darkAccent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkAccent,
      onPrimary: AppColors.darkOnAccent,
      surface: AppColors.darkBg,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.darkOverdue,
    ),
    LiquidGlassTheme.dark,
  );

  static ThemeData light() => _base(
    ColorScheme.fromSeed(
      seedColor: AppColors.lightAccent,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.lightAccent,
      onPrimary: AppColors.lightOnAccent,
      surface: AppColors.lightBg,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      error: AppColors.lightOverdue,
    ),
    LiquidGlassTheme.light,
  );

  static ThemeData _base(ColorScheme scheme, LiquidGlassTheme glass) {
    final base = ThemeData(colorScheme: scheme);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.14)),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppTypography.apply(base.textTheme),
      extensions: [glass],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.06),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        // Plain (non-state) values only: state-based styles are dropped by
        // ThemeData.lerp during the animated dark/light switch. Selected
        // styling is applied per chip via selectableChipStyle().
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.18)),
        backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: glass.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
