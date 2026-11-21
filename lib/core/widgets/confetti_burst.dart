import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight one-shot confetti (single CustomPainter, no packages, no
/// blur). Ignores pointers and removes itself via [onDone].
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.onDone, this.seed = 7});

  final VoidCallback onDone;
  final int seed;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward().whenComplete(widget.onDone);

  late final List<_Particle> _particles = _Particle.generate(widget.seed);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_particles, _controller),
      ),
    ),
  );
}

class _Particle {
  const _Particle(this.x, this.vx, this.vy, this.spin, this.size, this.color);

  final double x; // 0..1 launch position
  final double vx; // horizontal drift (fraction of width)
  final double vy; // initial upward speed (fraction of height)
  final double spin;
  final double size;
  final Color color;

  static const _palette = [
    Color(0xFF38BDF8),
    Color(0xFF22C55E),
    Color(0xFFFFB020),
    Color(0xFFFF5C72),
    Color(0xFF8B7CF6),
    Color(0xFF2DD4BF),
  ];

  static List<_Particle> generate(int seed) {
    final r = math.Random(seed);
    return [
      for (var i = 0; i < 70; i++)
        _Particle(
          0.2 + r.nextDouble() * 0.6,
          (r.nextDouble() - 0.5) * 0.9,
          0.9 + r.nextDouble() * 0.6,
          (r.nextDouble() - 0.5) * 12,
          5 + r.nextDouble() * 6,
          _palette[i % _palette.length],
        ),
    ];
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress) : super(repaint: progress);

  final List<_Particle> particles;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
    final paint = Paint();
    for (final p in particles) {
      // Launch from the bottom third, rise, then fall with gravity.
      final x = (p.x + p.vx * t) * size.width;
      final y = size.height * (0.75 - p.vy * t + 1.6 * t * t);
      paint.color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
