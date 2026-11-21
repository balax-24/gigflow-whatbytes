import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:gigflow/features/tasks/presentation/widgets/priority_style.dart';
import 'package:intl/intl.dart';

/// One pinned Tier-1 glass dock: greeting + shift progress (collapses on
/// scroll) above search + status + priority filters (always pinned).
/// Merging these keeps live blurs during scroll at 2 (dock + FAB).
class DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  DashboardHeaderDelegate({
    required this.topPadding,
    required this.horizontalPadding,
    required this.scale,
    required this.now,
    required this.email,
    required this.isDark,
    required this.stats,
    required this.filter,
    required this.searchController,
    required this.onThemeToggle,
    required this.onLogout,
    required this.onPriority,
    required this.onStatus,
    required this.onQuery,
    required this.onClearQuery,
    this.onSeed,
  });

  final double topPadding;
  final double horizontalPadding;
  final double scale;
  final DateTime now;
  final String email;
  final bool isDark;
  final ShiftStats stats;
  final TaskFilterState filter;
  final TextEditingController searchController;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final ValueChanged<TaskPriority?> onPriority;
  final ValueChanged<TaskStatusFilter> onStatus;
  final ValueChanged<String> onQuery;
  final VoidCallback onClearQuery;
  final VoidCallback? onSeed;

  static const double _collapsible = 104;
  static const double _row = 48;

  double get _collapsibleHeight => _collapsible * scale;

  @override
  double get minExtent => topPadding + 36 + 3 * _row * scale;

  @override
  double get maxExtent => minExtent + _collapsibleHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / _collapsibleHeight).clamp(0.0, 1.0);
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
                height: _row * scale,
                child: _SearchField(delegate: this),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _row * scale,
                child: _ChipRow(
                  children: [
                    for (final s in TaskStatusFilter.values)
                      ChoiceChip(
                        key: ValueKey('status-${s.name}'),
                        label: Text(s.label),
                        selected: filter.status == s,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onStatus(s);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: _row * scale,
                child: _ChipRow(
                  children: [
                    ChoiceChip(
                      key: const ValueKey('priority-all'),
                      label: const Text('All priorities'),
                      selected: filter.priority == null,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        onPriority(null);
                      },
                    ),
                    for (final p in TaskPriority.values)
                      ChoiceChip(
                        key: ValueKey('priority-${p.name}'),
                        avatar: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.colorOf(context),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 8),
                        ),
                        label: Text(p.label),
                        selected: filter.priority == p,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onPriority(p);
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
      oldDelegate.isDark != isDark ||
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

  String get _greeting {
    final h = delegate.now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final stats = delegate.stats;
    final name = delegate.email.split('@').first;
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
                        name.isEmpty ? _greeting : '$_greeting, $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM').format(delegate.now),
                        maxLines: 1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: delegate.isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(
                  delegate.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: delegate.onThemeToggle,
              ),
              IconButton(
                key: const ValueKey('logout-button'),
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: delegate.onLogout,
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
