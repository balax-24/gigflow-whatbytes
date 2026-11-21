import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferencesDataSource {
  LocalPreferencesDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const kFilterPriority = 'filter_priority'; // all|high|medium|low
  static const kFilterStatus = 'filter_status'; // all|incomplete|completed
  static const kFilterCategory = 'filter_category'; // all|<TaskCategory.name>
  static const kThemeMode = 'theme_mode'; // dark|light|lavender
  static const kOnboardingSeen = 'onboarding_seen'; // bool
  static const keys = {
    kFilterPriority,
    kFilterStatus,
    kFilterCategory,
    kThemeMode,
    kOnboardingSeen,
  };

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

  TaskCategory? readCategory() =>
      TaskCategory.values.asNameMap()[_prefs.getString(kFilterCategory)];

  Future<void> writeCategory(TaskCategory? c) =>
      _prefs.setString(kFilterCategory, c?.name ?? 'all');

  AppThemeOption readThemeOption() =>
      AppThemeOption.values.asNameMap()[_prefs.getString(kThemeMode)] ??
      AppThemeOption.dark;

  Future<void> writeThemeOption(AppThemeOption o) =>
      _prefs.setString(kThemeMode, o.name);

  bool readOnboardingSeen() => _prefs.getBool(kOnboardingSeen) ?? false;

  Future<void> writeOnboardingSeen() => _prefs.setBool(kOnboardingSeen, true);
}
