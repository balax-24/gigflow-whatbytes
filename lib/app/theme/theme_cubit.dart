import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_prefs.readThemeMode());

  final LocalPreferencesDataSource _prefs;

  bool get isDark => state != ThemeMode.light;

  Future<void> toggle() async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(next);
    await _prefs.writeThemeMode(next);
  }
}
