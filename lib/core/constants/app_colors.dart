// ════════════════════════════════════════
// lib/core/constants/app_colors.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';

/// Constantes de couleurs pour le design system "Calm & Focused".
class AppColors {
  // Base — dark theme
  static const Color background = Color(0xFF0A0A0F); // Presque noir
  static const Color surface = Color(0xFF13131A); // Cartes
  static const Color surfaceHigh = Color(0xFF1C1C26); // Éléments surélevés
  static const Color border = Color(0xFF2A2A38); // Bordures subtiles
  static const Color borderLight = Color(0xFF3A3A4E); // Bordures focus

  // Accent — Une seule couleur principale
  static const Color accent = Color(0xFF7C6EF6); // Violet doux
  static const Color accentLight = Color(0xFFAFA3FA); // Violet clair pour les textes
  static const Color accentFaded = Color(0x1A7C6EF6); // Violet très transparent pour backgrounds

  // Feedback
  static const Color success = Color(0xFF34C98A); // Vert doux
  static const Color error = Color(0xFFE05C6A); // Rouge doux
  static const Color warning = Color(0xFFF0A04B); // Orange doux

  // Textes
  static const Color textPrimary = Color(0xFFEEEEF8); // Blanc légèrement bleuté
  static const Color textSecondary = Color(0xFF8888AA); // Gris moyen
  static const Color textDisabled = Color(0xFF4A4A64); // Gris foncé

  // Gradients — Utilisés avec parcimonie
  static const List<Color> accentGradient = [
    Color(0xFF7C6EF6),
    Color(0xFF5B8DF6),
  ];

  /// Retourne la couleur avec l'opacité spécifiée.
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  // Ombres — très subtiles
  static const BoxShadow subtleShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow accentShadow = BoxShadow(
    color: Color(0x307C6EF6),
    blurRadius: 20,
    offset: Offset(0, 6),
  );
}
