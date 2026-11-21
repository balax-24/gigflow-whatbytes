import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/services/sync_status.dart';

/// Offline / syncing indicator. Solid translucent fill — never a blur.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key, required this.status});

  final SyncStatus status;

  static const offlineText = 'Offline — changes are saved on this device';
  static const syncingText = 'Syncing changes…';

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final scheme = Theme.of(context).colorScheme;
    final Widget child = switch (status) {
      SyncStatus.synced => const SizedBox.shrink(key: ValueKey('synced')),
      SyncStatus.offline => _pill(
        key: const ValueKey('offline'),
        context: context,
        color: glass.priorityMedium,
        leading: Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: glass.priorityMedium,
        ),
        text: offlineText,
      ),
      SyncStatus.syncing => _pill(
        key: const ValueKey('syncing'),
        context: context,
        color: scheme.primary,
        leading: SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
        text: syncingText,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  Widget _pill({
    required Key key,
    required BuildContext context,
    required Color color,
    required Widget leading,
    required String text,
  }) {
    final glass = context.glass;
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.16),
          glass.background,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
