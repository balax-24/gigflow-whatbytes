import 'package:flutter/material.dart';

/// Contrast ratios measured against bg and card surfaces (WCAG AA >= 4.5).
abstract final class AppColors {
  // Dark — Obsidian Glass
  static const darkBg = Color(0xFF070B14);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF8A97AB);
  static const darkPriorityHigh = Color(0xFFFF5C72);
  static const darkPriorityMedium = Color(0xFFFFB020);
  static const darkPriorityLow = Color(0xFF2DD4BF);
  static const darkComplete = Color(0xFF22C55E);
  static const darkOverdue = Color(0xFFF87171);
  static const darkAccent = Color(0xFF38BDF8);
  static const darkOnAccent = Color(0xFF070B14);

  // Light — Daylight Frost
  static const lightBg = Color(0xFFEEF3FA);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextMuted = Color(0xFF566378);
  static const lightPriorityHigh = Color(0xFFBE123C);
  static const lightPriorityMedium = Color(0xFF92400E);
  static const lightPriorityLow = Color(0xFF0F766E);
  static const lightComplete = Color(0xFF166534);
  static const lightOverdue = Color(0xFFB91C1C);
  static const lightAccent = Color(0xFF0369A1);
  static const lightOnAccent = Color(0xFFFFFFFF);

  static const darkOrbs = [
    Color(0x3D3B82F6), // cobalt 24% top-left
    Color(0x296366F1), // indigo 16% center-right
    Color(0x2E14B8A6), // teal 18% bottom-left
  ];
  static const lightOrbs = [
    Color(0x6B93C5FD),
    Color(0x61C7D2FE),
    Color(0x5C99F6E4),
  ];
}
