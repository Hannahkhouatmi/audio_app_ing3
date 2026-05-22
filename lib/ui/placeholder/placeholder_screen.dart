// ════════════════════════════════════════
// lib/ui/placeholder/placeholder_screen.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';

/// Écran de substitution épuré pour les sections de l'application en cours de développement.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (title) {
      case "Statistiques":
        icon = Icons.bar_chart_rounded;
      case "Lecteur Audio":
        icon = Icons.headphones_rounded;
      case "Favoris":
        icon = Icons.favorite_border_rounded;
      default:
        icon = Icons.info_outline_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadius.largeBR,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Bientôt disponible",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
