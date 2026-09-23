import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Official-looking "Google G" mark drawn with a [CustomPainter].
///
/// Drawn locally so the app does not ship (or download) an extra asset, and so
/// the mark always renders crisply at any size.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  /// Width/height of the square logo.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  /// Flutter's arc angles are in radians, clockwise, 0 rad = 3 o'clock.
  static double _deg(double degrees) => degrees * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.24;
    final double radius = (w - stroke) / 2;

    final Rect ring = Rect.fromCircle(
      center: Offset(w / 2, h / 2),
      radius: radius,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red – top arc (left-top ➜ right-top)
    paint.color = _red;
    canvas.drawArc(ring, _deg(-155), _deg(95), false, paint);

    // Blue – right arc (right-top ➜ right-bottom)
    paint.color = _blue;
    canvas.drawArc(ring, _deg(-60), _deg(90), false, paint);

    // Green – bottom arc (right-bottom ➜ bottom-left)
    paint.color = _green;
    canvas.drawArc(ring, _deg(30), _deg(90), false, paint);

    // Yellow – left arc (bottom-left ➜ top-left)
    paint.color = _yellow;
    canvas.drawArc(ring, _deg(120), _deg(90), false, paint);

    // Blue crossbar – from the centre out to the right edge.
    canvas.drawRect(
      Rect.fromLTRB(w / 2, h / 2 - stroke / 2, w, h / 2 + stroke / 2),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
