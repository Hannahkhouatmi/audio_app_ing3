// ════════════════════════════════════════
// lib/core/widgets/app_snackbar.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

enum SnackBarType { success, error, info, warning }

/// SnackBar personnalisé unifié et propre.
class AppSnackBar {
  static void show(
    BuildContext context,
    String message,
    SnackBarType type,
  ) {
    Color typeColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        typeColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
      case SnackBarType.error:
        typeColor = AppColors.error;
        icon = Icons.error_outline_rounded;
      case SnackBarType.info:
        typeColor = AppColors.accent;
        icon = Icons.info_outline_rounded;
      case SnackBarType.warning:
        typeColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      content: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.mediumBR,
          border: Border(
            left: BorderSide(color: typeColor, width: 3.5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: typeColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
