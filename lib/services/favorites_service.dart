import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/track_model.dart';
import 'favorites_service_interface.dart';

/// Service gérant les favoris de pistes audio stockés dans Firestore.
///
/// Arborescence Firestore :
///   users/{uid}/favorites/{trackId}
class FavoritesService implements FavoritesServiceInterface {
  final FirebaseFirestore _firestore;

  FavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favoritesCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  @override
  Future<void> addFavorite(String uid, TrackModel track) async {
    if (uid.isEmpty) return;
    await _favoritesCol(uid).doc(track.id).set(track.toMap());
  }

  @override
  Future<void> removeFavorite(String uid, String trackId) async {
    if (uid.isEmpty || trackId.isEmpty) return;
    await _favoritesCol(uid).doc(trackId).delete();
  }

  @override
  Stream<List<TrackModel>> watchFavorites(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _favoritesCol(uid).snapshots().map((snap) {
      return snap.docs
          .map((doc) => TrackModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<bool> isFavorite(String uid, String trackId) async {
    if (uid.isEmpty || trackId.isEmpty) return false;
    final doc = await _favoritesCol(uid).doc(trackId).get();
    return doc.exists;
  }
}