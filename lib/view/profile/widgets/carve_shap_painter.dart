
// Custom painter for the curved decoration at the top
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CurveShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height / 50);
    path.quadraticBezierTo(
        size.width,
        size.height / 1.5,
        size.width ,
        size.height/ 5
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}