// ════════════════════════════════════════
// lib/providers/playlist_provider.dart
// ════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track_model.dart';
import '../services/playlist_api_service.dart';

/// Service singleton pour l'API playlist.
final playlistApiServiceProvider = Provider<PlaylistApiService>((ref) {
  return PlaylistApiService();
});

/// Requête de recherche courante (modifiée par l'UI).
final playlistQueryProvider = StateProvider<String>((ref) => 'top hits 2024');

/// Playlist récupérée via l'API en fonction de la requête courante.
/// autoDispose pour éviter de garder les résultats en mémoire si l'écran est quitté.
final playlistProvider = FutureProvider.autoDispose<List<TrackModel>>((
  ref,
) async {
  final query = ref.watch(playlistQueryProvider);
  final service = ref.watch(playlistApiServiceProvider);
  if (query.trim().isEmpty) {
    return service.getDefaultPlaylist();
  }
  return service.search(query: query);
});
