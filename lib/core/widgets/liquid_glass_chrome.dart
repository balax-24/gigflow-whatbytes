import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/specular_rim_painter.dart';

/// Tier-1 glass: the ONLY widget allowed to contain a BackdropFilter.
/// Never place inside a ListView / SliverList item.
class LiquidGlassChrome extends StatelessWidget {
  const LiquidGlassChrome({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: CustomPaint(
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
                colors: glass.chromeFill,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
