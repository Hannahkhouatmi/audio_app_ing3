// ════════════════════════════════════════
// lib/core/widgets/loading_dots.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// indicateur de chargement 3 points qui pulsent en séquence.
class LoadingDots extends StatefulWidget {
  final Color color;
  final double dotSize;

  const LoadingDots({
    super.key,
    this.color = AppColors.accent,
    this.dotSize = 6.0,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Décalage de phase pour l'effet de vague (staggered)
        // index * 150ms de délai sur 1000ms de durée totale => index * 0.15 de déphasage
        final double phase = (index * 0.2) % 1.0;
        final double val = (_controller.value - phase) % 1.0;
        
        // On calcule le scale : monte à 1.5, descend à 1.0
        double scale = 1.0;
        if (val < 0.4) {
          scale = 1.0 + (val / 0.4) * 0.5;
        } else if (val < 0.8) {
          scale = 1.5 - ((val - 0.4) / 0.4) * 0.5;
        }
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              color: AppColors.withOpacity(
                widget.color,
                val < 0.8 ? 1.0 : 0.4,
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.dotSize * 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(0),
          const SizedBox(width: 6),
          _buildDot(1),
          const SizedBox(width: 6),
          _buildDot(2),
        ],
      ),
    );
  }
}
