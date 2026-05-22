// ════════════════════════════════════════
// lib/services/biometric_result.dart
// ════════════════════════════════════════

/// Résultat d'une tentative d'authentification biométrique.
enum BiometricResult {
  success,
  failed,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  notAvailable,
}
