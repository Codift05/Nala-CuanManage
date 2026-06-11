import 'dart:math';
import 'package:flutter/material.dart';

class SpeedometerChart extends StatelessWidget {
  final double score; // 0 to 100
  final Color activeColor;
  final Color backgroundColor;

  const SpeedometerChart({
    super.key,
    required this.score,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2, // Semi-circle: width is 2x height
      child: CustomPaint(
        painter: _SpeedometerPainter(
          score: score,
          activeColor: activeColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double score;
  final Color activeColor;
  final Color backgroundColor;

  _SpeedometerPainter({
    required this.score,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.12;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track (semi-circle)
    canvas.drawArc(rect, pi, pi, false, bgPaint);

    // Draw active track
    final sweepAngle = pi * (score / 100).clamp(0.0, 1.0);
    canvas.drawArc(rect, pi, sweepAngle, false, activePaint);

    // Draw needle
    final needleAngle = pi + sweepAngle;
    final needleLength = radius * 0.7;
    final needleEndX = center.dx + needleLength * cos(needleAngle);
    final needleEndY = center.dy + needleLength * sin(needleAngle);

    final needlePaint = Paint()
      ..color = const Color(0xFF1E293B) // Dark gray/black for needle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(needleEndX, needleEndY), needlePaint);

    // Draw center circle
    final centerCirclePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 12, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
