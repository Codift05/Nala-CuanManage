import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetProgressBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color activeColor;
  final Color trackColor;

  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.activeColor,
    this.trackColor = const Color(0xFFF0F0F0),
  });

  @override
  Widget build(BuildContext context) {
    // Determine the color: if percentage > 100, we can force it to red if needed,
    // but we can also just let the caller pass the correct activeColor based on logic.
    final displayPercent = percentage.clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1A1A),
                fontWeight: percentage > 100
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: percentage > 100 ? activeColor : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * (displayPercent / 100),
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
