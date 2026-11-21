import 'package:flutter/rendering.dart';

/// 1.2px diagonal specular rim: bright top-left -> clear centre -> tinted
/// bottom-right bounce light.
class SpecularRimPainter extends CustomPainter {
  const SpecularRimPainter({
    required this.borderRadius,
    required this.highlight,
    required this.shade,
    this.strokeWidth = 1.2,
  });

  final BorderRadius borderRadius;
  final Color highlight;
  final Color shade;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect.deflate(strokeWidth / 2));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, highlight.withValues(alpha: 0), shade],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(SpecularRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.highlight != highlight ||
      oldDelegate.shade != shade ||
      oldDelegate.strokeWidth != strokeWidth;
}
