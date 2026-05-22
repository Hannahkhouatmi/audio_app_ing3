import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track_model.dart';
import '../services/quran_api_service.dart';

/// Provider pour le service Quran API.
final quranApiServiceProvider = Provider<QuranApiService>((ref) {
  return QuranApiService();
});

/// État de la recherche des récitateurs.
final reciterSearchQueryProvider = StateProvider<String>((ref) => '');

/// Liste des récitateurs disponibles (recitations).
final recitersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(quranApiServiceProvider);
  return service.getReciters();
});

/// Liste filtrée des récitateurs en fonction de la recherche.
final filteredRecitersProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final recitersAsync = ref.watch(recitersProvider);
  final query = ref.watch(reciterSearchQueryProvider).toLowerCase();

  return recitersAsync.whenData((reciters) {
    if (query.isEmpty) return reciters;
    return reciters.where((r) {
      final name = (r['reciter_name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  });
});

/// Provider pour les noms des chapitres (sourates).
final chapterNamesProvider = FutureProvider<Map<int, String>>((ref) async {
  final service = ref.watch(quranApiServiceProvider);
  return service.getChapterNames();
});

/// Récitateur sélectionné par l'utilisateur.
final selectedReciterProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Playlist des sourates pour le récitateur sélectionné.
final quranPlaylistProvider = FutureProvider.autoDispose<List<TrackModel>>((ref) async {
  final reciter = ref.watch(selectedReciterProvider);
  if (reciter == null) return [];
  
  final service = ref.watch(quranApiServiceProvider);
  final names = await ref.watch(chapterNamesProvider.future);
  
  final id = reciter['id'] as int;
  final name = reciter['reciter_name'] ?? 'Récitateur';
  
  return service.getSurahsForRecitation(id, name, names);
});
