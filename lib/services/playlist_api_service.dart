import 'package:dio/dio.dart';
import '../models/track_model.dart';

/// recupere une playlist dynamique depuis l'API iTunes Search
class PlaylistApiService {
  final Dio _dio;

  PlaylistApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://itunes.apple.com',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ),
          );

  /// Récupère une playlist par mot-clé de recherche
  /// Retourne uniquement les pistes ayant un `previewUrl` valide
  Future<List<TrackModel>> search({
    String query = 'top hits',
    int limit = 25,
  }) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'term': query,
          'entity': 'song',
          'limit': limit,
          'media': 'music',
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return const [];

      final results = data['results'];
      if (results is! List) return const [];

      return results
          .whereType<Map<String, dynamic>>()
          .map(TrackModel.fromItunes)
          .where((t) => t.audioUrl.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw PlaylistApiException(_mapDioError(e));
    } catch (_) {
      throw PlaylistApiException(
        'Impossible de charger la playlist. Veuillez réessayer.',
      );
    }
  }

  /// Playlist par défaut affichée au lancement.
  Future<List<TrackModel>> getDefaultPlaylist() =>
      search(query: 'top hits 2024');

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Délai d\'attente dépassé. Vérifiez votre connexion.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (e.response?.statusCode != null) {
      return 'Erreur serveur (${e.response!.statusCode}).';
    }
    return 'Erreur réseau. Veuillez réessayer.';
  }
}

/// Exception spécifique aux erreurs de l'API playlist
class PlaylistApiException implements Exception {
  final String message;
  PlaylistApiException(this.message);

  @override
  String toString() => message;
}
