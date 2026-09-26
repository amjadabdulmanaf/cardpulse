import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedPercentText extends StatefulWidget {
  final double value; // Percentage value e.g. 41.0
  final TextStyle? style;
  final String suffix;
  final Duration duration;
  final int delayMs;

  const AnimatedPercentText({
    super.key,
    required this.value,
    this.style,
    this.suffix = '%',
    this.duration = const Duration(milliseconds: 750),
    this.delayMs = 0,
  });

  @override
  State<AnimatedPercentText> createState() => _AnimatedPercentTextState();
}

class _AnimatedPercentTextState extends State<AnimatedPercentText> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant AnimatedPercentText oldWidget) {
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
        return Text(
          '${_animation.value.toInt()}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
