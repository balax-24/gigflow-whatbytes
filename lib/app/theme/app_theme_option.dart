import 'package:flutter/material.dart';

/// User-selectable look. Lavender is a soft light theme that echoes a
/// purple brand palette.
enum AppThemeOption {
  dark,
  light,
  lavender;

  String get label => switch (this) {
    AppThemeOption.dark => 'Obsidian',
    AppThemeOption.light => 'Daylight',
    AppThemeOption.lavender => 'Lavender',
  };

  String get emoji => switch (this) {
    AppThemeOption.dark => '🌙',
    AppThemeOption.light => '☀️',
    AppThemeOption.lavender => '💜',
  };

  ThemeMode get mode =>
      this == AppThemeOption.dark ? ThemeMode.dark : ThemeMode.light;

  AppThemeOption get next =>
      AppThemeOption.values[(index + 1) % AppThemeOption.values.length];
}
