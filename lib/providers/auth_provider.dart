import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Provider pour l'instance d'AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// StreamProvider écoutant les changements d'état d'authentification Firebase
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// FutureProvider récupérant les données complémentaires de l'utilisateur Firestore
final currentUserDataProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  // Ré-évalue lorsque le flux d'authentification change
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getCurrentUserData();
});

/// StateProvider pour conserver le message d'erreur d'authentification actuel
final authErrorProvider = StateProvider<String?>((ref) => null);
