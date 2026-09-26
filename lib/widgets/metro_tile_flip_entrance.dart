import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Windows 8 Metro 3D Y-Axis Flip Entrance Animation
class MetroTileFlipEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;

  const MetroTileFlipEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<MetroTileFlipEntrance> createState() => _MetroTileFlipEntranceState();
}

class _MetroTileFlipEntranceState extends State<MetroTileFlipEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Flips on Y-axis from -90 deg (-pi/2) to 0 deg
    _flipAnimation = Tween<double>(begin: -math.pi / 2, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // Ensure animation starts after the first frame is painted on screen
    _delayTimer = Timer(Duration(milliseconds: widget.delayMs + 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
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
      animation: _controller,
      builder: (context, child) {
        final angle = _flipAnimation.value;
        final opacity = _opacityAnimation.value;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective depth
            ..rotateY(angle),
          child: Opacity(
            opacity: opacity,
            child: widget.child,
          ),
        );
      },
    );
  }
}
