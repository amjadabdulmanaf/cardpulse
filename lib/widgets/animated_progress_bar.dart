import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? color;
  final Color backgroundColor;
  final Duration duration;
  final int delayMs;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.color,
    this.backgroundColor = const Color(0xFF080B0F),
    this.duration = const Duration(milliseconds: 750),
    this.delayMs = 0,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> with SingleTickerProviderStateMixin {
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
    _animation = Tween<double>(begin: 0.0, end: widget.value.clamp(0.001, 1.0)).animate(
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
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value.clamp(0.001, 1.0),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            color: widget.backgroundColor,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _animation.value.clamp(0.001, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.gradient == null ? (widget.color ?? const Color(0xFF00FFA3)) : null,
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(widget.height / 2),
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
