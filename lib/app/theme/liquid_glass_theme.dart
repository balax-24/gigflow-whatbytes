import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/app_colors.dart';

@immutable
class LiquidGlassTheme extends ThemeExtension<LiquidGlassTheme> {
  const LiquidGlassTheme({
    required this.background,
    required this.cardFill,
    required this.chromeFill,
    required this.rimHighlight,
    required this.rimShade,
    required this.shadow,
    required this.blurSigma,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.complete,
    required this.overdue,
    required this.textMuted,
    required this.orbs,
  });

  final Color background;
  final List<Color> cardFill;
  final List<Color> chromeFill;
  final Color rimHighlight;
  final Color rimShade;
  final Color shadow;
  final double blurSigma;
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;
  final Color complete;
  final Color overdue;
  final Color textMuted;
  final List<Color> orbs;

  static const dark = LiquidGlassTheme(
    background: AppColors.darkBg,
    cardFill: [Color(0x1FFFFFFF), Color(0x0DFFFFFF)],
    chromeFill: [Color(0x29FFFFFF), Color(0x14FFFFFF)],
    rimHighlight: Color(0x66FFFFFF),
    rimShade: Color(0x1A38BDF8),
    shadow: Color(0x40000000),
    blurSigma: 16,
    priorityHigh: AppColors.darkPriorityHigh,
    priorityMedium: AppColors.darkPriorityMedium,
    priorityLow: AppColors.darkPriorityLow,
    complete: AppColors.darkComplete,
    overdue: AppColors.darkOverdue,
    textMuted: AppColors.darkTextMuted,
    orbs: AppColors.darkOrbs,
  );

  static const light = LiquidGlassTheme(
    background: AppColors.lightBg,
    cardFill: [Color(0xD9FFFFFF), Color(0xB3FFFFFF)],
    chromeFill: [Color(0xB3FFFFFF), Color(0x8CFFFFFF)],
    rimHighlight: Color(0xFFFFFFFF),
    rimShade: Color(0x330369A1),
    shadow: Color(0x1A0F172A),
    blurSigma: 16,
    priorityHigh: AppColors.lightPriorityHigh,
    priorityMedium: AppColors.lightPriorityMedium,
    priorityLow: AppColors.lightPriorityLow,
    complete: AppColors.lightComplete,
    overdue: AppColors.lightOverdue,
    textMuted: AppColors.lightTextMuted,
    orbs: AppColors.lightOrbs,
  );

  @override
  LiquidGlassTheme copyWith() => this;

  @override
  LiquidGlassTheme lerp(covariant LiquidGlassTheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> l(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return LiquidGlassTheme(
      background: c(background, other.background),
      cardFill: l(cardFill, other.cardFill),
      chromeFill: l(chromeFill, other.chromeFill),
      rimHighlight: c(rimHighlight, other.rimHighlight),
      rimShade: c(rimShade, other.rimShade),
      shadow: c(shadow, other.shadow),
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      priorityHigh: c(priorityHigh, other.priorityHigh),
      priorityMedium: c(priorityMedium, other.priorityMedium),
      priorityLow: c(priorityLow, other.priorityLow),
      complete: c(complete, other.complete),
      overdue: c(overdue, other.overdue),
      textMuted: c(textMuted, other.textMuted),
      orbs: l(orbs, other.orbs),
    );
  }
}

extension LiquidGlassContext on BuildContext {
  LiquidGlassTheme get glass =>
      Theme.of(this).extension<LiquidGlassTheme>() ?? LiquidGlassTheme.dark;
}
