import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/loading_dots.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/secure_delete_service.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<bool?> _confirmDelete(BuildContext context, TrackModel track) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeBR,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Supprimer ce favori ?',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La suppression nécessite une vérification biométrique.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: AppRadius.mediumBR,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${track.title} — ${track.artist}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            label: 'Supprimer',
            prefixIcon: Icons.fingerprint_rounded,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TrackModel track,
  ) async {
    final confirm = await _confirmDelete(context, track);
    if (confirm != true) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final service = ref.read(secureDeleteServiceProvider);
    final result = await service.deleteWithBiometric(user.uid, track.id);

    if (!context.mounted) return;

    switch (result) {
      case SecureDeleteResult.success:
        AppSnackBar.show(
          context,
          '« ${track.title} » retiré des favoris',
          SnackBarType.success,
        );
      case SecureDeleteResult.biometricFailed:
        AppSnackBar.show(
          context,
          'Authentification biométrique échouée. Suppression annulée.',
          SnackBarType.error,
        );
      case SecureDeleteResult.biometricNotAvailable:
        AppSnackBar.show(
          context,
          'Biométrie indisponible sur cet appareil. Configurez Windows Hello / empreinte.',
          SnackBarType.warning,
        );
      case SecureDeleteResult.error:
        AppSnackBar.show(
          context,
          'Erreur lors de la suppression.',
          SnackBarType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.screenPadding.add(
                const EdgeInsets.only(top: 16, bottom: 8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Favoris',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  favs.maybeWhen(
                    data: (list) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentFaded,
                        borderRadius: AppRadius.pillBR,
                      ),
                      child: Text(
                        '${list.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: Row(
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Suppression protégée par biométrie',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: favs.when(
                loading: () => const Center(child: LoadingDots()),
                error: (_, __) => Center(
                  child: Text(
                    'Impossible de charger les favoris',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return _emptyState();
                  }
                  return ListView.builder(
                    padding: AppSpacing.screenPadding.add(
                      const EdgeInsets.only(bottom: 16),
                    ),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final t = tracks[index];
                      return _FavoriteTile(
                        track: t,
                        onPlay: () {
                          ref
                              .read(audioPlayerServiceProvider)
                              .setQueue(tracks, startIndex: index);
                        },
                        onDelete: () => _handleDelete(context, ref, t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: AppRadius.largeBR,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: AppColors.textDisabled,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun favori',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez des morceaux depuis le lecteur',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final TrackModel track;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _FavoriteTile({
    required this.track,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('fav_${track.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // On garde l'item visible — le stream Firestore le retirera
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.withOpacity(AppColors.error, 0.15),
          borderRadius: AppRadius.largeBR,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.fingerprint_rounded,
          color: AppColors.error,
          size: 28,
        ),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onPlay,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.smallBR,
              child: SizedBox(
                width: 48,
                height: 48,
                child: (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                    ? Image.network(
                        track.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Supprimer (biométrie)',
              onPressed: onDelete,
              icon: const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceHigh,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.textSecondary,
        size: 18,
      ),
    );
  }
}
