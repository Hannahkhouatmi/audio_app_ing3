// ════════════════════════════════════════
// lib/models/monthly_goal_model.dart
// ════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

/// Objectif mensuel d'écoute.
/// Stocké dans `users/{uid}/goals/{YYYY-MM}`.
class MonthlyGoalModel {
  /// Format "YYYY-MM" (ex: "2025-04")
  final String month;
  final int targetMinutes;
  final int achievedMinutes;
  final DateTime updatedAt;

  const MonthlyGoalModel({
    required this.month,
    required this.targetMinutes,
    required this.achievedMinutes,
    required this.updatedAt,
  });

  /// Progression en pourcentage (0.0 → 1.0).
  double get progress {
    if (targetMinutes <= 0) return 0;
    return (achievedMinutes / targetMinutes).clamp(0.0, 1.0).toDouble();
  }

  /// True si l'objectif est atteint ou dépassé.
  bool get isAchieved => achievedMinutes >= targetMinutes && targetMinutes > 0;

  /// Clé de document pour un mois donné.
  static String monthKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'targetMinutes': targetMinutes,
      'achievedMinutes': achievedMinutes,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MonthlyGoalModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final ts = map['updatedAt'];
    DateTime when;
    if (ts is Timestamp) {
      when = ts.toDate();
    } else if (ts is String) {
      when = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      when = DateTime.now();
    }

    return MonthlyGoalModel(
      month: map['month'] ?? documentId,
      targetMinutes: (map['targetMinutes'] as num?)?.toInt() ?? 0,
      achievedMinutes: (map['achievedMinutes'] as num?)?.toInt() ?? 0,
      updatedAt: when,
    );
  }

  MonthlyGoalModel copyWith({int? targetMinutes, int? achievedMinutes}) {
    return MonthlyGoalModel(
      month: month,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      achievedMinutes: achievedMinutes ?? this.achievedMinutes,
      updatedAt: DateTime.now(),
    );
  }
}
