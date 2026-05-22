// ════════════════════════════════════════
// lib/models/track_model.dart
// ════════════════════════════════════════

/// Modèle représentant une piste audio dans l'application.
class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl;

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TrackModel(
      id: documentId,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      coverUrl: map['coverUrl'],
    );
  }
}
