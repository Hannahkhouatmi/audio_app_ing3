import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'biometric_service.dart';
import 'favorites_service_interface.dart';

enum SecureDeleteResult { 
  success, 
  biometricFailed, 
  biometricNotAvailable, 
  error 
}

/// Service gérant la suppression sécurisée d'un favori avec validation biométrique et historique de sécurité dans Firestore
class SecureDeleteService {
  final BiometricService _biometricService;
  final FavoritesServiceInterface _favoritesService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SecureDeleteService(this._biometricService, this._favoritesService);

  /// Supprime un favori après validation biométrique de l'utilisateur
  Future<SecureDeleteResult> deleteWithBiometric(String uid, String trackId) async {
    SecureDeleteResult result = SecureDeleteResult.error;

    try {
      final isAvailable = await _biometricService.isAvailable();
      if (!isAvailable) {
        result = SecureDeleteResult.biometricNotAvailable;
        await _logAction(uid, trackId, "delete_favorite_failed_no_biometrics");
        return result;
      }

      final biometricResult = await _biometricService.authenticate();
      if (biometricResult == BiometricResult.success) {
        await _favoritesService.removeFavorite(uid, trackId);
        result = SecureDeleteResult.success;
        await _logAction(uid, trackId, "delete_favorite_success");
      } else {
        result = SecureDeleteResult.biometricFailed;
        await _logAction(uid, trackId, "delete_favorite_biometric_failed");
      }
    } catch (_) {
      result = SecureDeleteResult.error;
      await _logAction(uid, trackId, "delete_favorite_error");
    }

    return result;
  }

  /// Enregistre les détails de l'action de sécurité dans Firestore
  Future<void> _logAction(String uid, String trackId, String actionResult) async {
    try {
      String deviceDesc = "Web Chrome";
      if (!kIsWeb) {
        deviceDesc = Platform.isAndroid ? "Android Device" : (Platform.isIOS ? "iOS Device" : Platform.operatingSystem);
      }

      await _firestore.collection('security_logs').add({
        'userId': uid,
        'trackId': trackId,
        'action': 'secure_delete_favorite',
        'result': actionResult,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceDesc,
      });
    } catch (_) {
      // Ignorer l'erreur d'enregistrement de log pour ne pas bloquer le flux principal
    }
  }
}
