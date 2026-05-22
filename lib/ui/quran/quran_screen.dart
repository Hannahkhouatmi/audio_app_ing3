import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_dots.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/quran_provider.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recitersAsync = ref.watch(filteredRecitersProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final quranPlaylist = ref.watch(quranPlaylistProvider);

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
              child: Text(
                'Saint Coran',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Barre de recherche pour filtrer les récitateurs
            Padding(
              padding: AppSpacing.screenPadding.add(const EdgeInsets.only(bottom: 12)),
              child: AppTextField(
                label: 'Rechercher un récitateur',
                controller: _searchController,
                prefixIcon: Icons.search_rounded,
                onChanged: (value) {
                  ref.read(reciterSearchQueryProvider.notifier).state = value;
                },
              ),
            ),

            // Sélecteur de récitateur
            Padding(
              padding: AppSpacing.screenPadding.add(const EdgeInsets.only(bottom: 16)),
              child: recitersAsync.when(
                data: (reciters) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mediumBR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: (selectedReciter != null && reciters.any((r) => r['id'] == selectedReciter['id'])) 
                          ? reciters.firstWhere((r) => r['id'] == selectedReciter['id'])
                          : null,
                      hint: Text(
                        'Choisir un récitateur (${reciters.length})',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: reciters.map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r['reciter_name'] ?? 'Inconnu',
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                        ),
                      )).toList(),
                      onChanged: (val) {
                        ref.read(selectedReciterProvider.notifier).state = val;
                      },
                    ),
                  ),
                ),
                loading: () => const SizedBox(height: 48, child: Center(child: LoadingDots())),
                error: (e, _) => const Text('Erreur de chargement'),
              ),
            ),

            // Liste des sourates
            Expanded(
              child: selectedReciter == null
                  ? _buildEmptyState('Sélectionnez un récitateur pour charger les sourates')
                  : quranPlaylist.when(
                      data: (tracks) => ListView.builder(
                        padding: AppSpacing.screenPadding.add(const EdgeInsets.only(bottom: 16)),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final t = tracks[index];
                          return _QuranTrackTile(
                            track: t,
                            onTap: () => ref.read(audioPlayerServiceProvider).setQueue(tracks, startIndex: index),
                          );
                        },
                      ),
                      loading: () => const Center(child: LoadingDots()),
                      error: (e, _) => Center(child: Text('Erreur: $e')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _QuranTrackTile extends ConsumerWidget {
  final TrackModel track;
  final VoidCallback onTap;

  const _QuranTrackTile({required this.track, required this.onTap});

  Future<void> _toggleFavorite(WidgetRef ref, BuildContext context) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final favService = ref.read(favoritesServiceProvider);
    final isFav = ref.read(favoritesStreamProvider).value?.any((t) => t.id == track.id) ?? false;

    try {
      if (isFav) {
        await favService.removeFavorite(user.uid, track.id);
        if (context.mounted) AppSnackBar.show(context, 'Retiré des favoris', SnackBarType.info);
      } else {
        await favService.addFavorite(user.uid, track);
        if (context.mounted) AppSnackBar.show(context, 'Ajouté aux favoris', SnackBarType.success);
      }
    } catch (_) {
      if (context.mounted) AppSnackBar.show(context, 'Erreur lors de l\'opération.', SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider).value;
    final isCurrent = currentTrack?.id == track.id;
    final isFav = ref.watch(isFavoriteReactiveProvider(track.id));

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: CircleAvatar(
          backgroundColor: isCurrent ? AppColors.accent : AppColors.surfaceHigh,
          child: Icon(
            isCurrent ? Icons.volume_up : Icons.play_arrow,
            color: isCurrent ? Colors.white : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          track.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isCurrent ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(track.artist, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.error : AppColors.textDisabled,
          ),
          onPressed: () => _toggleFavorite(ref, context),
        ),
      ),
    );
  }
}
