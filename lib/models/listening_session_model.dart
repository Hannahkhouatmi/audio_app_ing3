// ════════════════════════════════════════
// lib/models/listening_session_model.dart
// ════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente une session d'écoute persistée dans Firestore.
/// Stockée dans `users/{uid}/sessions/{auto-id}`.
class ListeningSessionModel {
  final String id;
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final int listenedSeconds;
  final DateTime listenedAt;

  const ListeningSessionModel({
    required this.id,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    required this.listenedSeconds,
    required this.listenedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'trackTitle': trackTitle,
      'trackArtist': trackArtist,
      'listenedSeconds': listenedSeconds,
      'listenedAt': Timestamp.fromDate(listenedAt),
    };
  }

  factory ListeningSessionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final ts = map['listenedAt'];
    DateTime when;
    if (ts is Timestamp) {
      when = ts.toDate();
    } else if (ts is String) {
      when = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      when = DateTime.now();
    }

    return ListeningSessionModel(
      id: documentId,
      trackId: map['trackId'] ?? '',
      trackTitle: map['trackTitle'] ?? '',
      trackArtist: map['trackArtist'] ?? '',
      listenedSeconds: (map['listenedSeconds'] as num?)?.toInt() ?? 0,
      listenedAt: when,
    );
  }
}
