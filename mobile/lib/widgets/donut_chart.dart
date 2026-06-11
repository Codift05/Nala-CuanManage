import 'package:flutter/material.dart';
import 'dart:math';

class DonutChartData {
  final double value;
  final Color color;

  DonutChartData(this.value, this.color);
}

class DonutChart extends StatelessWidget {
  final List<DonutChartData> data;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.data,
    this.strokeWidth = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutChartPainter(data, strokeWidth),
      child: Container(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartData> data;
  final double strokeWidth;

  _DonutChartPainter(this.data, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    double total = data.fold(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -pi / 2; // Start from top
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: min(size.width / 2, size.height / 2) - strokeWidth / 2,
    );

    for (var item in data) {
      final sweepAngle = (item.value / total) * 2 * pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt; // Use butt so they connect flush

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
