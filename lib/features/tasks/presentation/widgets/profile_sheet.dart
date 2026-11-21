import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';
import 'package:gigflow/features/tasks/presentation/widgets/priority_style.dart';

/// "⋯" sheet: account, appearance, sign out.
Future<void> showProfileSheet(
  BuildContext context, {
  required String email,
  required ShiftStats stats,
  required int totalTasks,
  required ThemeCubit themeCubit,
  required VoidCallback onSignOut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ProfileSheet(
      email: email,
      stats: stats,
      totalTasks: totalTasks,
      themeCubit: themeCubit,
      onSignOut: () {
        Navigator.of(sheetContext).pop();
        onSignOut();
      },
    ),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({
    required this.email,
    required this.stats,
    required this.totalTasks,
    required this.themeCubit,
    required this.onSignOut,
  });

  final String email;
  final ShiftStats stats;
  final int totalTasks;
  final ThemeCubit themeCubit;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();
    return LiquidGlassChrome(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const SizedBox(width: 40, height: 4),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.split('@').first,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '$totalTasks', label: 'Tasks'),
              _Stat(
                value: '${stats.todayDone}/${stats.todayTotal}',
                label: 'Done today',
              ),
              _Stat(value: '${stats.overdue}', label: 'Overdue'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Appearance', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          StreamBuilder<AppThemeOption>(
            stream: themeCubit.stream,
            initialData: themeCubit.state,
            builder: (context, snap) => Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final o in AppThemeOption.values)
                  SelectableChip(
                    key: ValueKey('theme-${o.name}'),
                    label: '${o.emoji} ${o.label}',
                    selected: snap.data == o,
                    onSelected: () {
                      HapticFeedback.selectionClick();
                      themeCubit.select(o);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const ValueKey('logout-button'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(50),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
