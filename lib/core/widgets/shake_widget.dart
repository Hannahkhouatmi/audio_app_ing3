// ════════════════════════════════════════
// lib/core/widgets/shake_widget.dart
// ════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';

/// Un widget de secousse horizontal pour signaler visuellement une erreur.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final double shakeRange;
  final Duration duration;

  const ShakeWidget({
    super.key,
    required this.child,
    this.shakeRange = 8.0,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Déclenche l'animation de secousse (3 oscillations).
  void shake() {
    _controller.forward(from: 0.0);
  }

  double _getTranslation(double value) {
    // 3 oscillations complètes : sin(value * 3 * 2 * pi)
    // On veut amortir à la fin
    if (value == 0.0 || value == 1.0) return 0.0;
    const double pi2 = 3.1415926535897932 * 2;
    return widget.shakeRange * (1.0 - value) * (3.0 * (1.0 - value)).clamp(0, 1) * (sin(value * 3.0 * pi2));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_getTranslation(_controller.value), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
