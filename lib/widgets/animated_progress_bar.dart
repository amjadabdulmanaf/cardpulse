import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? color;
  final Color backgroundColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.color,
    this.backgroundColor = const Color(0xFF080B0F),
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.clamp(0.001, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: backgroundColor,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animValue.clamp(0.001, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: gradient == null ? (color ?? const Color(0xFF00FFA3)) : null,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
