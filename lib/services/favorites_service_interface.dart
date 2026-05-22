import '../models/track_model.dart';

/// Interface définissant le contrat pour la gestion des favoris de pistes audio.
abstract class FavoritesServiceInterface {
  /// Ajoute une piste audio aux favoris de l'utilisateur.
  Future<void> addFavorite(String uid, TrackModel track);

  /// Retire une piste audio des favoris de l'utilisateur.
  Future<void> removeFavorite(String uid, String trackId);

  /// Écoute en temps réel la liste des favoris de l'utilisateur.
  Stream<List<TrackModel>> watchFavorites(String uid);

  /// Vérifie si une piste audio est dans les favoris de l'utilisateur.
  Future<bool> isFavorite(String uid, String trackId);
}
