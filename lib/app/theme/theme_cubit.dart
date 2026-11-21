import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';

class ThemeCubit extends Cubit<AppThemeOption> {
  ThemeCubit(this._prefs) : super(_prefs.readThemeOption());

  final LocalPreferencesDataSource _prefs;

  bool get isDark => state == AppThemeOption.dark;

  Future<void> select(AppThemeOption option) async {
    if (option == state) return;
    emit(option);
    await _prefs.writeThemeOption(option);
  }

  /// Header shortcut: cycles Obsidian -> Daylight -> Lavender.
  Future<void> cycle() => select(state.next);
}
