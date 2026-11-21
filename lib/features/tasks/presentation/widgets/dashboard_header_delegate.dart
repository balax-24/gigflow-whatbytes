import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigflow/app/theme/app_theme_option.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:gigflow/features/tasks/domain/utils/relative_due.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:gigflow/features/tasks/presentation/widgets/priority_style.dart';
import 'package:intl/intl.dart';

/// One pinned Tier-1 glass dock: greeting + shift progress (collapses on
/// scroll) above search + status + priority + category filters (pinned).
/// Merging these keeps live blurs during scroll at 2 (dock + FAB).
class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  DashboardHeaderDelegate({
    required this.topPadding,
    required this.horizontalPadding,
    required this.scale,
    required this.now,
    required this.email,
    required this.themeOption,
    required this.stats,
    required this.filter,
    required this.searchController,
    required this.onThemeCycle,
    required this.onProfile,
    required this.onPriority,
    required this.onStatus,
    required this.onCategory,
    required this.onQuery,
    required this.onClearQuery,
    this.onSeed,
  });

  final double topPadding;
  final double horizontalPadding;
  final double scale;
  final DateTime now;
  final String email;
  final AppThemeOption themeOption;
  final ShiftStats stats;
  final TaskFilterState filter;
  final TextEditingController searchController;
  final VoidCallback onThemeCycle;
  final VoidCallback onProfile;
  final ValueChanged<TaskPriority?> onPriority;
  final ValueChanged<TaskStatusFilter> onStatus;
  final ValueChanged<TaskCategory?> onCategory;
  final ValueChanged<String> onQuery;
  final VoidCallback onClearQuery;
  final VoidCallback? onSeed;

  static const double _collapsible = 104;
  static const double _row = 48;

  double get _collapsibleHeight => _collapsible * scale;

  @override
  double get minExtent => topPadding + 38 + 4 * _row * scale;

  @override
  double get maxExtent => minExtent + _collapsibleHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / _collapsibleHeight).clamp(0.0, 1.0);
    final row = _row * scale;
    return SizedBox.expand(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: LiquidGlassChrome(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding + 8,
            horizontalPadding,
            10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 1 - t,
                  child: SizedBox(
                    height: _collapsibleHeight,
                    child: _SummarySection(delegate: this),
                  ),
                ),
              ),
              SizedBox(
                height: row,
                child: _SearchField(delegate: this),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: row,
                child: _ChipRow(
                  children: [
                    for (final s in TaskStatusFilter.values)
                      SelectableChip(
                        key: ValueKey('status-${s.name}'),
                        label: s.label,
                        selected: filter.status == s,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          onStatus(s);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: row,
                child: _ChipRow(
                  children: [
                    SelectableChip(
                      key: const ValueKey('priority-all'),
                      tooltip: 'All priorities',
                      label: 'All',
                      selected: filter.priority == null,
                      onSelected: () {
                        HapticFeedback.selectionClick();
                        onPriority(null);
                      },
                    ),
                    for (final p in TaskPriority.values)
                      SelectableChip(
                        key: ValueKey('priority-${p.name}'),
                        label: p.label,
                        dotColor: p.colorOf(context),
                        selected: filter.priority == p,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          onPriority(p);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: row,
                child: _ChipRow(
                  children: [
                    SelectableChip(
                      key: const ValueKey('category-all'),
                      tooltip: 'All categories',
                      label: '🏷️ All',
                      selected: filter.category == null,
                      onSelected: () {
                        HapticFeedback.selectionClick();
                        onCategory(null);
                      },
                    ),
                    for (final c in TaskCategory.values)
                      SelectableChip(
                        key: ValueKey('category-${c.name}'),
                        label: '${c.emoji} ${c.label}',
                        selected: filter.category == c,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          onCategory(c);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(DashboardHeaderDelegate oldDelegate) =>
      oldDelegate.topPadding != topPadding ||
      oldDelegate.horizontalPadding != horizontalPadding ||
      oldDelegate.scale != scale ||
      oldDelegate.now != now ||
      oldDelegate.email != email ||
      oldDelegate.themeOption != themeOption ||
      oldDelegate.stats != stats ||
      oldDelegate.filter != filter;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.zero,
    itemCount: children.length,
    separatorBuilder: (_, _) => const SizedBox(width: 8),
    itemBuilder: (_, i) => Center(child: children[i]),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.delegate});

  final DashboardHeaderDelegate delegate;

  @override
  Widget build(BuildContext context) {
    final hasText = delegate.filter.query.isNotEmpty;
    return TextField(
      key: const ValueKey('task-search'),
      controller: delegate.searchController,
      onChanged: delegate.onQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search tasks',
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: delegate.onClearQuery,
              )
            : null,
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.delegate});

  final DashboardHeaderDelegate delegate;

  IconData get _themeIcon => switch (delegate.themeOption) {
    AppThemeOption.dark => Icons.dark_mode_rounded,
    AppThemeOption.light => Icons.light_mode_rounded,
    AppThemeOption.lavender => Icons.auto_awesome_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final stats = delegate.stats;
    final name = delegate.email.split('@').first;
    final date = DateFormat('EEEE, d MMMM').format(delegate.now);
    final option = delegate.themeOption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onLongPress: delegate.onSeed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        greetingFor(delegate.now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        name.isEmpty ? date : '$name · $date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('theme-button'),
                tooltip: 'Theme: ${option.label}. Tap for ${option.next.label}',
                icon: Icon(_themeIcon),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  delegate.onThemeCycle();
                },
              ),
              IconButton(
                key: const ValueKey('profile-button'),
                tooltip: 'Profile & settings',
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: delegate.onProfile,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                stats.todayTotal == 0
                    ? 'Nothing due today'
                    : stats.todayDone == stats.todayTotal
                    ? 'Shift cleared 🎉 ${stats.todayDone}/${stats.todayTotal}'
                    : '${stats.todayDone} of ${stats.todayTotal} done today',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
            if (stats.overdue > 0)
              Semantics(
                label: '${stats.overdue} overdue tasks',
                excludeSemantics: true,
                child: TagPill(
                  label: '${stats.overdue} overdue',
                  icon: Icons.warning_amber_rounded,
                  color: glass.overdue,
                ),
              ),
            if (stats.highOpen > 0) ...[
              const SizedBox(width: 6),
              Semantics(
                label: '${stats.highOpen} open high priority tasks',
                excludeSemantics: true,
                child: TagPill(
                  label: '${stats.highOpen} high',
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  color: glass.priorityHigh,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(end: stats.progress),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              color: glass.complete,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
