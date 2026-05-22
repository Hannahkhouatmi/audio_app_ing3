import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service gérant l'authentification et l'enregistrement avec Firebase.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flux informant des changements d'état d'authentification.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Récupère l'utilisateur Firebase actuellement connecté.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Récupère les informations complémentaires de l'utilisateur stockées dans Firestore.
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Connecte un utilisateur via son email et mot de passe.
  Future<void> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception("Une erreur inconnue est survenue lors de la connexion.");
    }
  }

  /// Enregistre un nouvel utilisateur après vérification de l'âge minimum.
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required DateTime birthDate,
    String? phone,
  }) async {
    // Validation d'âge côté client (>= 13 ans)
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    if (age < 13) {
      throw Exception('Vous devez avoir au moins 13 ans pour créer un compte.');
    }

    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception("Création de compte échouée. Veuillez réessayer.");
      }

      final userModel = UserModel(
        uid: user.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        birthDate: birthDate,
        email: email.trim(),
        phone: phone?.trim(),
        createdAt: DateTime.now(),
      );

      // Sauvegarde des données utilisateur dans Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception("Une erreur inconnue est survenue lors de l'inscription.");
    }
  }

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      throw Exception("Une erreur est survenue lors de l'envoi du mail.");
    }
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Traduit et formate les erreurs Firebase Authentication.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return "Mot de passe incorrect";
      case 'user-not-found':
        return "Aucun compte associé à cet email";
      case 'email-already-in-use':
        return "Cet email est déjà utilisé";
      case 'weak-password':
        return "Mot de passe trop faible (min. 8 caractères)";
      case 'too-many-requests':
        return "Trop de tentatives. Réessayez dans quelques minutes";
      case 'network-request-failed':
        return "Vérifiez votre connexion internet";
      case 'invalid-email':
        return "Format d'email invalide";
      default:
        return "Une erreur est survenue. Veuillez réessayer";
    }
  }
}
