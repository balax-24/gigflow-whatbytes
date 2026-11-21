import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/liquid_glass_card.dart';

class EmptyTasksView extends StatelessWidget {
  const EmptyTasksView({
    super.key,
    required this.isFiltering,
    required this.onClearFilters,
    this.query = '',
  });

  final bool isFiltering;
  final VoidCallback onClearFilters;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = query.trim();
    final title = isFiltering
        ? (q.isEmpty
              ? 'No matches for these filters 🔍'
              : 'Nothing matches “$q” 🔍')
        : 'Nothing on your plate 🍃';
    final body = isFiltering
        ? 'Try another priority, status, category or day.'
        : 'Tap + New Task to plan your shift, or go grab a chai ☕';
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: LiquidGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(
              isFiltering ? Icons.filter_alt_off_rounded : Icons.inbox_rounded,
              size: 40,
              color: context.glass.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isFiltering) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear search & filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static placeholder cards while the first snapshot loads (no shimmer).
class TaskSkeletonList extends StatelessWidget {
  const TaskSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final bar = context.glass.textMuted.withValues(alpha: 0.18);
    Widget line(double w, double h) => DecoratedBox(
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(width: w, height: h),
    );
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LiquidGlassCard(
              child: Row(
                children: [
                  line(26, 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        line(180, 14),
                        const SizedBox(height: 8),
                        line(120, 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
