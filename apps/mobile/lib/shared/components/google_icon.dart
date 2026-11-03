import 'package:flutter/material.dart';

/// Pixel-perfect Google 'G' official 4-color logo
class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(w / 2, h / 2);
    final rect = Rect.fromLTWH(0, 0, w, h);
    final innerRect = Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.56);

    // Red: Top arc
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..arcTo(rect, -2.4, 1.6, false)
      ..arcTo(innerRect, -0.8, -1.6, false)
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow: Left arc
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..arcTo(rect, -4.0, 1.6, false)
      ..arcTo(innerRect, -2.4, -1.6, false)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green: Bottom arc
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..arcTo(rect, 0.78, 1.6, false)
      ..arcTo(innerRect, 2.38, -1.6, false)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue: Right bar & right arc
    paint.color = const Color(0xFF4285F4);
    final rightBluePath = Path()
      ..arcTo(rect, 0.0, 0.78, false)
      ..lineTo(center.dx, center.dy + h * 0.18)
      ..lineTo(center.dx, center.dy - h * 0.18)
      ..lineTo(w * 0.98, center.dy - h * 0.18)
      ..arcTo(rect, -0.2, 0.2, false)
      ..close();
    canvas.drawPath(rightBluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
