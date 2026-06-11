import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> dataPoints; // Values between 0.0 and 1.0 (normalized)
  final List<String> labels; // X-axis labels e.g. ['Apr', 'Mei', 'Jun']
  final Color lineColor;

  const TrendLineChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendLinePainter(
                dataPoints: dataPoints,
                lineColor: lineColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((label) {
            return Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;

  _TrendLinePainter({
    required this.dataPoints,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final double stepX = size.width / (dataPoints.length - 1);

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * stepX;
      // Invert Y so that 1.0 is at the top (0.0) and 0.0 is at the bottom (size.height)
      final double y = size.height - (dataPoints[i] * size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Draw the dots
    for (final point in points) {
      canvas.drawCircle(point, 6.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
