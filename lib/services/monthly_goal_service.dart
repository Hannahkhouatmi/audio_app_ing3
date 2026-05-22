// ════════════════════════════════════════
// lib/services/monthly_goal_service.dart
// ════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_goal_model.dart';

/// Service gérant les objectifs mensuels d'écoute.
///
/// Arborescence Firestore :
///   users/{uid}/goals/{YYYY-MM}
class MonthlyGoalService {
  final FirebaseFirestore _firestore;

  MonthlyGoalService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _goalDoc(
    String uid,
    String monthKey,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc(monthKey);
  }

  /// Récupère l'objectif du mois courant (ou null s'il n'existe pas).
  Future<MonthlyGoalModel?> getCurrentGoal(String uid) async {
    if (uid.isEmpty) return null;
    final key = MonthlyGoalModel.monthKey(DateTime.now());
    final doc = await _goalDoc(uid, key).get();
    if (!doc.exists || doc.data() == null) return null;
    return MonthlyGoalModel.fromMap(doc.data()!, doc.id);
  }

  /// Écoute en temps réel l'objectif du mois courant.
  Stream<MonthlyGoalModel?> watchCurrentGoal(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    final key = MonthlyGoalModel.monthKey(DateTime.now());
    return _goalDoc(uid, key).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return MonthlyGoalModel.fromMap(snap.data()!, snap.id);
    });
  }

  /// Définit ou met à jour l'objectif mensuel (targetMinutes >= 0).
  Future<void> setGoal({
    required String uid,
    required int targetMinutes,
    DateTime? month,
  }) async {
    if (uid.isEmpty) throw ArgumentError('uid requis');
    if (targetMinutes < 0) throw ArgumentError('targetMinutes doit être >= 0');

    final m = month ?? DateTime.now();
    final key = MonthlyGoalModel.monthKey(m);
    await _goalDoc(uid, key).set({
      'month': key,
      'targetMinutes': targetMinutes,
      'achievedMinutes': FieldValue.increment(
        0,
      ), // crée le champ s'il n'existe pas
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Met à jour les minutes accomplies (recalcul depuis le total réel).
  Future<void> updateAchievedMinutes({
    required String uid,
    required int achievedMinutes,
    DateTime? month,
  }) async {
    if (uid.isEmpty) return;
    final m = month ?? DateTime.now();
    final key = MonthlyGoalModel.monthKey(m);
    await _goalDoc(uid, key).set({
      'month': key,
      'achievedMinutes': achievedMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
