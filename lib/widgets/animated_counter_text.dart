import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedCounterText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  const AnimatedCounterText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '₹',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedVal, child) {
        final formatted = Formatters.formatCurrencyWithoutSymbol(animatedVal);
        return Text(
          '$prefix$formatted',
          style: style,
        );
      },
    );
  }
}
