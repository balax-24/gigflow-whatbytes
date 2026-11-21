import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';

/// Static mesh backdrop painted once behind every route (per theme).
class AmbientMeshBackground extends StatelessWidget {
  const AmbientMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _AmbientMeshPainter(
              background: glass.background,
              orbs: glass.orbs,
            ),
            isComplex: true,
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientMeshPainter extends CustomPainter {
  const _AmbientMeshPainter({required this.background, required this.orbs});

  final Color background;
  final List<Color> orbs;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    _orb(
      canvas,
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.75,
      orbs[0],
    );
    _orb(
      canvas,
      Offset(size.width * 0.90, size.height * 0.45),
      size.width * 0.65,
      orbs[1],
    );
    _orb(
      canvas,
      Offset(size.width * 0.25, size.height * 0.88),
      size.width * 0.70,
      orbs[2],
    );
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AmbientMeshPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.orbs != orbs;
}
