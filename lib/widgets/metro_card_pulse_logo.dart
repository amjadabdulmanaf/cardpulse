import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CardPulse Logo matching attached card image
class MetroCardPulseLogo extends StatelessWidget {
  final double width;
  final double height;

  const MetroCardPulseLogo({
    super.key,
    this.width = 36.0,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = height * 0.20;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E12), // Deep Obsidian Card Background
        borderRadius: BorderRadius.circular(borderRadius), // Rounded Card Border
        border: Border.all(
          color: const Color(0xFF00A3FF), // Thick Vibrant Blue Card Outline
          width: math.max(1.8, height * 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius * 0.8),
        child: Stack(
          children: [
            // Dark Horizontal Magnetic Band
            Positioned(
              top: height * 0.38,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.20,
                color: const Color(0xFF1E1E1E),
              ),
            ),

            // Solid Gold Square SIM Chip
            Positioned(
              left: width * 0.12,
              top: height * 0.14,
              child: Container(
                width: width * 0.16,
                height: height * 0.26,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B), // Amber Gold
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),

            // Vibrant Rounded Pulse Wave Path
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPulsePathPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPulsePathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(2.0, size.height * 0.09);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00A3FF), // Electric Cyan Blue
          Color(0xFF00E676), // Bright Pulse Green
          Color(0xFFFFB800), // Amber Yellow
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.10, size.height * 0.62);
    path.lineTo(size.width * 0.28, size.height * 0.62);
    path.lineTo(size.width * 0.38, size.height * 0.18);
    path.lineTo(size.width * 0.50, size.height * 0.88);
    path.lineTo(size.width * 0.62, size.height * 0.38);
    path.lineTo(size.width * 0.70, size.height * 0.62);
    path.lineTo(size.width * 0.90, size.height * 0.62);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
