import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/specular_rim_painter.dart';

/// Tier-2 glass: zero blur, zero clip, zero saveLayer. Safe inside lists.
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.accentTint,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? accentTint;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final borderRadius = BorderRadius.circular(radius);
    final top = accentTint == null
        ? glass.cardFill.first
        : Color.alphaBlend(
            accentTint!.withValues(alpha: 0.10),
            glass.cardFill.first,
          );
    return CustomPaint(
      foregroundPainter: SpecularRimPainter(
        borderRadius: borderRadius,
        highlight: glass.rimHighlight,
        shade: glass.rimShade,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, glass.cardFill.last],
          ),
          // RRect shadow => analytic fast path on Impeller.
          boxShadow: [
            BoxShadow(
              color: glass.shadow,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
