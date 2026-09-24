import 'package:flutter/material.dart';

class AnimatedPercentText extends StatelessWidget {
  final double value; // Percentage value e.g. 41.0
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  const AnimatedPercentText({
    super.key,
    required this.value,
    this.style,
    this.suffix = '%',
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Text(
          '${animVal.toInt()}$suffix',
          style: style,
        );
      },
    );
  }
}
