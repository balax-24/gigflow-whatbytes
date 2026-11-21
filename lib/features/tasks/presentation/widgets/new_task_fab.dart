import 'package:flutter/material.dart';

import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';

/// Floating "+ New Task" pill (Tier-1 glass, one of max two live blurs).
class NewTaskFab extends StatelessWidget {
  const NewTaskFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  static const fabKey = ValueKey('new-task-fab');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'New task',
      excludeSemantics: true,
      child: LiquidGlassChrome(
        borderRadius: BorderRadius.circular(999),
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: fabKey,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'New Task',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
