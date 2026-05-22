import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lecture en cours',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentTrack != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NowPlayingCard(track: currentTrack),
                )
              else
                Column(
                  children: [
                    Icon(
                      Icons.headphones_outlined,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune récitation en cours',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez une sourate dans l\'onglet Coran',
                      style: GoogleFonts.inter(
                        color: AppColors.textDisabled,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte du morceau en cours de lecture (cover + slider + contrôles).
class _NowPlayingCard extends ConsumerWidget {
  final TrackModel track;
  const _NowPlayingCard({required this.track});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleFavorite(WidgetRef ref, BuildContext context) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final favService = ref.read(favoritesServiceProvider);
    final isFav =
        ref.read(favoritesStreamProvider).value?.any((t) => t.id == track.id) ??
        false;

    try {
      if (isFav) {
        await favService.removeFavorite(user.uid, track.id);
        if (context.mounted) {
          AppSnackBar.show(context, 'Retiré des favoris', SnackBarType.info);
        }
      } else {
        await favService.addFavorite(user.uid, track);
        if (context.mounted) {
          AppSnackBar.show(context, 'Ajouté aux favoris', SnackBarType.success);
        }
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Erreur lors de l\'opération.',
          SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(audioPlayerServiceProvider);
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value ?? Duration.zero;
    final isFav = ref.watch(isFavoriteReactiveProvider(track.id));

    final totalMs = duration.inMilliseconds.toDouble();
    final posMs = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.withOpacity(AppColors.accent, 0.12),
            AppColors.surface,
          ],
        ),
        borderRadius: AppRadius.largeBR,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image / Cover
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: AppRadius.largeBR,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.largeBR,
              child: (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                  ? Image.network(
                      track.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverFallback(),
                    )
                  : _coverFallback(),
            ),
          ),
          const SizedBox(height: 32),

          // Titre et Récitateur
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _toggleFavorite(ref, context),
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: isFav ? AppColors.error : AppColors.textSecondary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              min: 0,
              max: totalMs > 0 ? totalMs : 1,
              value: totalMs > 0 ? posMs : 0,
              onChanged: (value) {
                service.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contrôles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 42,
                onPressed: service.previous,
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 48,
                  onPressed: service.togglePlayPause,
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 42,
                onPressed: service.next,
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: AppColors.surfaceHigh,
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.accent,
        size: 80,
      ),
    );
  }
}
