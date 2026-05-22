
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track_model.dart';
import '../services/favorites_service.dart';
import '../services/favorites_service_interface.dart';
import '../services/biometric_service.dart';
import '../services/secure_delete_service.dart';
import 'auth_provider.dart';
import 'biometric_provider.dart';

/// Instance unique du service Firestore des favoris
final favoritesServiceProvider = Provider<FavoritesServiceInterface>((ref) {
  return FavoritesService();
});

/// Service de suppression sécurisée
final secureDeleteServiceProvider = Provider<SecureDeleteService>((ref) {
  final biometric = ref.watch(biometricServiceProvider);
  final favorites = ref.watch(favoritesServiceProvider);
  return SecureDeleteService(biometric, favorites);
});

/// Flux temps réel des favoris de l'utilisateur courant
final favoritesStreamProvider = StreamProvider<List<TrackModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(favoritesServiceProvider).watchFavorites(user.uid);
});

/// Famille de providers : true si la piste donnée est dans les favoris.
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, trackId) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Future.value(false);
  return ref.watch(favoritesServiceProvider).isFavorite(user.uid, trackId);
});

/// Helper : retourne true si [trackId] figure dans la liste des favoris streamée
/// Reactif au flux : meilleur pour les UI temps réel que [isFavoriteProvider]
final isFavoriteReactiveProvider = Provider.family<bool, String>((
  ref,
  trackId,
) {
  final favs = ref.watch(favoritesStreamProvider).value ?? const [];
  return favs.any((t) => t.id == trackId);
});

/// Utilisé par la BiometricService injectée
final biometricServiceInstanceProvider = Provider<BiometricService>((ref) {
  return ref.watch(biometricServiceProvider);
});
