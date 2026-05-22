// ════════════════════════════════════════
// lib/core/widgets/app_button.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Un bouton épuré et stylisé selon le design system.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? prefixIcon;
  final double? width;
  final bool isFullWidth;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.isFullWidth = false,
    this.variant = AppButtonVariant.primary,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.prefixIcon,
    this.width,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _scale = 0.98);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _scale = 1.0);
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color textColor;
    Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = AppColors.accent;
        textColor = Colors.white;
      case AppButtonVariant.secondary:
        bg = AppColors.surfaceHigh;
        textColor = AppColors.textPrimary;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        textColor = AppColors.accent;
        border = Border.all(color: AppColors.accent, width: 1.5);
      case AppButtonVariant.danger:
        bg = AppColors.withOpacity(AppColors.error, 0.1);
        textColor = AppColors.error;
    }

    final childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.prefixIcon != null) ...[
          Icon(widget.prefixIcon, size: 18, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: textColor,
          ),
        ),
      ],
    );

    Widget buttonWidget = Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Container(
        height: 52,
        width: widget.isFullWidth ? double.infinity : widget.width,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillBR,
          border: border,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            borderRadius: AppRadius.pillBR,
            splashColor: AppColors.accentFaded,
            highlightColor: Colors.transparent,
            child: Center(
              child: childContent,
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: buttonWidget,
      ),
    );
  }
}
