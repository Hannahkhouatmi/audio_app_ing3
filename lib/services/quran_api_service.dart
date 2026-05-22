import 'package:dio/dio.dart';
import '../models/track_model.dart';

/// Service pour récupérer les récitations du Coran depuis l'API Quran.com (v4).
/// C'est l'API la plus stable et utilisée par la plupart des applications modernes.
class QuranApiService {
  final Dio _dio;

  QuranApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.quran.com/api/v4',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                responseType: ResponseType.json,
              ),
            );

  /// Récupère la liste des récitateurs (recitations).
  Future<List<Map<String, dynamic>>> getReciters({String lang = 'fr'}) async {
    try {
      final response = await _dio.get('/resources/recitations', queryParameters: {
        'language': lang,
      });
      final data = response.data;
      if (data is Map && data.containsKey('recitations')) {
        return List<Map<String, dynamic>>.from(data['recitations']);
      }
      return [];
    } catch (e) {
      throw QuranApiException('Impossible de charger les récitateurs. Vérifiez votre connexion.');
    }
  }

  /// Récupère la liste des sourates avec leurs noms.
  Future<Map<int, String>> getChapterNames({String lang = 'fr'}) async {
    try {
      final response = await _dio.get('/chapters', queryParameters: {
        'language': lang,
      });
      final data = response.data;
      final Map<int, String> names = {};
      if (data is Map && data.containsKey('chapters')) {
        for (var chapter in data['chapters']) {
          names[chapter['id']] = chapter['name_complex'] ?? chapter['name_simple'] ?? 'Sourate';
        }
      }
      return names;
    } catch (e) {
      return {};
    }
  }

  /// Récupère les fichiers audio pour un récitateur donné et construit la playlist.
  Future<List<TrackModel>> getSurahsForRecitation(int recitationId, String reciterName, Map<int, String> chapterNames) async {
    try {
      // Cette API retourne les 114 fichiers audio d'un coup pour ce récitateur
      final response = await _dio.get('/chapter_recitations/$recitationId');
      final data = response.data;
      
      if (data is Map && data.containsKey('audio_files')) {
        final List files = data['audio_files'];
        return files.map((file) {
          final int chapterId = file['chapter_id'];
          final String audioUrl = file['audio_url'];
          
          // S'assurer que l'URL est absolue
          final String finalUrl = audioUrl.startsWith('http') 
              ? audioUrl 
              : 'https://download.quranicaudio.com/$audioUrl';

          return TrackModel(
            id: 'quran_${recitationId}_$chapterId',
            title: chapterNames[chapterId] ?? 'Sourate $chapterId',
            artist: reciterName,
            audioUrl: finalUrl,
            album: 'Saint Coran',
            coverUrl: 'https://static.quran.com/images/share.png',
            durationSeconds: (file['duration'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw QuranApiException('Erreur lors de la récupération des fichiers audio.');
    }
  }
}

class QuranApiException implements Exception {
  final String message;
  QuranApiException(this.message);
  @override
  String toString() => message;
}
