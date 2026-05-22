// ════════════════════════════════════════
// lib/services/biometric_service.dart
// ════════════════════════════════════════

import 'biometric_result.dart';
export 'biometric_result.dart';

import 'biometric_platform_stub.dart'
    if (dart.library.html) 'biometric_platform_web.dart'
    if (dart.library.io) 'biometric_platform_io.dart' as platform;

/// Service gérant l'authentification biométrique multi-plateforme.
///
/// - Mobile : empreinte digitale (local_auth)
/// - PC natif (Windows/macOS) : Windows Hello / Touch ID (local_auth)
/// - Navigateur (Chrome/Edge) : WebAuthn → Windows Hello / Touch ID
class BiometricService {
  /// Vérifie si le matériel biométrique est disponible sur l'appareil.
  Future<bool> isAvailable() => platform.isBiometricAvailable();

  /// Vérifie si au moins une empreinte ou un visage est enregistré.
  Future<bool> hasBiometrics() => platform.hasBiometricsEnrolled();

  /// Tente d'authentifier l'utilisateur par biométrie.
  Future<BiometricResult> authenticate() => platform.authenticateBiometric();

  /// Ouvre les réglages système (sécurité / biométrie).
  Future<bool> openBiometricSettings() => platform.openBiometricSettings();
}
