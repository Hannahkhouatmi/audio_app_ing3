import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../providers/audio_player_provider.dart';

/// Petit lecteur persistant affiché au-dessus de la barre de navigation
/// dès qu'une piste est chargée.
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider).value;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value;

    if (track == null) return const SizedBox.shrink();

    final progress = (duration != null && duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final service = ref.read(audioPlayerServiceProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de progression fine
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Pochette
                  ClipRRect(
                    borderRadius: AppRadius.smallBR,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child:
                          (track.coverUrl != null && track.coverUrl!.isNotEmpty)
                          ? Image.network(
                              track.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _coverFallback(),
                            )
                          : _coverFallback(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Titre + artiste
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: service.togglePlayPause,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.accent,
                      size: 28,
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

  Widget _coverFallback() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
