// ════════════════════════════════════════
// lib/core/widgets/app_card.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.onTap,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: padding,
      child: child,
    );

    final boxDecoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.largeBR,
      border: hasBorder ? Border.all(color: AppColors.border) : null,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: boxDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.largeBR,
            splashColor: AppColors.accentFaded,
            highlightColor: Colors.transparent,
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: boxDecoration,
      child: cardContent,
    );
  }
}
