// ════════════════════════════════════════
// lib/providers/biometric_provider.dart
// ════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';

/// Provider pour l'instance de BiometricService.
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// FutureProvider vérifiant si la biométrie est supportée et disponible.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometricServiceProvider).isAvailable();
});

/// StateProvider comptant le nombre de tentatives biométriques échouées.
final biometricAttemptsProvider = StateProvider<int>((ref) => 0);

/// StateProvider indiquant si l'utilisateur est verrouillé (lockout temporaire de 2 min).
final biometricLockedProvider = StateProvider<bool>((ref) => false);
