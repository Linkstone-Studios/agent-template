import 'package:flutter/material.dart';

/// Custom brand icons for social authentication
class BrandIcons {
  BrandIcons._();

  /// Google "G" logo icon
  /// Uses the official Google colors and precise vector paths
  static Widget google({double size = 24}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }

  /// Apple logo icon (uses Material Icons)
  static Widget apple({double size = 24, Color? color}) {
    return Icon(Icons.apple, size: size, color: color);
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define Google's brand colors
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    // The vector paths below are based on a standard 24x24 bounding box.
    // We scale the canvas so the 24x24 paths perfectly fit the requested widget size.
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // 1. Red Path (Top)
    final Path redPath = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // 2. Blue Path (Right & Center Bar)
    final Path bluePath = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 3. Green Path (Bottom)
    final Path greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 4. Yellow Path (Left)
    final Path yellowPath = Path()
      ..moveTo(5.84, 14.09)
      ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12.0)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..lineTo(5.84, 14.09)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
