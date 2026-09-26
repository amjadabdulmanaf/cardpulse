import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AnimatedCounterText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;
  final int delayMs;

  const AnimatedCounterText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '₹',
    this.duration = const Duration(milliseconds: 900),
    this.delayMs = 0,
  });

  @override
  State<AnimatedCounterText> createState() => _AnimatedCounterTextState();
}

class _AnimatedCounterTextState extends State<AnimatedCounterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.delayMs <= 0) {
      _controller.forward(from: 0.0);
    } else {
      _delayTimer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) {
          _controller.forward(from: 0.0);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCounterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final formatted = Formatters.formatCurrencyWithoutSymbol(_animation.value);
        return Text(
          '${widget.prefix}$formatted',
          style: widget.style,
        );
      },
    );
  }
}
