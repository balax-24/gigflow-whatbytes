import 'package:flutter/material.dart' show ThemeMode;
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesDataSource {
  LocalPreferencesDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const kFilterPriority = 'filter_priority'; // all|high|medium|low
  static const kFilterStatus = 'filter_status'; // all|incomplete|completed
  static const kThemeMode = 'theme_mode'; // dark|light
  static const keys = {kFilterPriority, kFilterStatus, kThemeMode};

  TaskPriority? readPriority() {
    final raw = _prefs.getString(kFilterPriority);
    return raw == null || raw == 'all' ? null : TaskPriority.fromName(raw);
  }

  Future<void> writePriority(TaskPriority? p) =>
      _prefs.setString(kFilterPriority, p?.name ?? 'all');

  TaskStatusFilter readStatus() =>
      TaskStatusFilter.values.asNameMap()[_prefs.getString(kFilterStatus)] ??
      TaskStatusFilter.all;

  Future<void> writeStatus(TaskStatusFilter s) =>
      _prefs.setString(kFilterStatus, s.name);

  ThemeMode readThemeMode() => _prefs.getString(kThemeMode) == 'light'
      ? ThemeMode.light
      : ThemeMode.dark;

  Future<void> writeThemeMode(ThemeMode m) =>
      _prefs.setString(kThemeMode, m == ThemeMode.light ? 'light' : 'dark');
}
