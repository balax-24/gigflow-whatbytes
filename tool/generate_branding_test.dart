// Renders the GigFlow app icon PNGs (no external tools needed).
// Run: flutter test tool/generate_branding_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate branding PNGs', () async {
    Directory('assets/branding').createSync(recursive: true);
    await _render('assets/branding/app_icon.png', withBackground: true);
    await _render(
      'assets/branding/app_icon_foreground.png',
      withBackground: false,
    );
  });
}

Future<void> _render(String path, {required bool withBackground}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0, 0, size, size);

  if (withBackground) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF070B14), Color(0xFF0B1A33)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      const Offset(size * 0.2, size * 0.18),
      size * 0.7,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF3B82F6).withValues(alpha: 0.55),
                const Color(0xFF3B82F6).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: const Offset(size * 0.2, size * 0.18),
                radius: size * 0.7,
              ),
            ),
    );
    canvas.drawCircle(
      const Offset(size * 0.85, size * 0.9),
      size * 0.6,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF14B8A6).withValues(alpha: 0.5),
                const Color(0xFF14B8A6).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: const Offset(size * 0.85, size * 0.9),
                radius: size * 0.6,
              ),
            ),
    );
  }

  // Glyph scale: full icon uses ~62% of canvas; adaptive foreground keeps
  // the glyph inside the central 66% safe zone (~46%).
  final glyph = withBackground ? 0.62 : 0.46;
  final g = size * glyph;
  final o = (size - g) / 2;
  Offset p(double x, double y) => Offset(o + x * g, o + y * g);

  // Glass check-badge ring
  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    g / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = g * 0.055
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0x55FFFFFF), Color(0xFF38BDF8)],
      ).createShader(rect),
  );

  // Lightning bolt
  final bolt = Path()
    ..moveTo(p(0.56, 0.14).dx, p(0.56, 0.14).dy)
    ..lineTo(p(0.28, 0.56).dx, p(0.28, 0.56).dy)
    ..lineTo(p(0.48, 0.56).dx, p(0.48, 0.56).dy)
    ..lineTo(p(0.42, 0.86).dx, p(0.42, 0.86).dy)
    ..lineTo(p(0.72, 0.42).dx, p(0.72, 0.42).dy)
    ..lineTo(p(0.52, 0.42).dx, p(0.52, 0.42).dy)
    ..close();
  canvas.drawPath(
    bolt,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7DD3FC), Color(0xFF2DD4BF)],
      ).createShader(rect),
  );

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
