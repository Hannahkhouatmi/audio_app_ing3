import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/auth_provider.dart';

/// Feuille modale affichant les infos du profil et permettant la déconnexion.
class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeBR,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Se déconnecter ?',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Vous devrez vous authentifier à nouveau pour accéder à l\'application.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          AppButton.danger(
            label: 'Déconnexion',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Stop la lecture audio et nettoie l'UID du player
      await ref.read(audioPlayerServiceProvider).stop();

      // Efface l'email mémorisé pour la prochaine session
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remembered_email');
      } catch (_) {}

      await ref.read(authServiceProvider).logout();

      if (context.mounted) {
        // Ferme la bottom sheet puis route vers l'écran d'auth
        Navigator.of(context).pop();
        context.go(AppRoutes.biometric);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Erreur lors de la déconnexion. Réessayez.',
          SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle de la bottom sheet
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Avatar + nom
            userData.when(
              loading: () => const SizedBox(
                height: 70,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => _identity('Utilisateur', null, null),
              data: (u) => _identity(
                u?.fullName ?? 'Utilisateur',
                u?.email,
                u?.createdAt,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton.danger(
              label: 'Se déconnecter',
              prefixIcon: Icons.logout_rounded,
              isFullWidth: true,
              onPressed: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(String name, String? email, DateTime? createdAt) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accentFaded,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(name),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accentLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (email != null && email.isNotEmpty)
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (createdAt != null)
                Text(
                  'Membre depuis ${DateFormat('MMMM yyyy', 'fr_FR').format(createdAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
