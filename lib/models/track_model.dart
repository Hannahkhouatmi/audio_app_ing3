
/// piste audio
class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl;
  final String? album;
  final int durationSeconds; // 0 = inconnu

  const TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
    this.album,
    this.durationSeconds = 0,
  });

  /// mm:ss
  String get formattedDuration {
    if (durationSeconds <= 0) return '--:--';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'album': album,
      'durationSeconds': durationSeconds,
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TrackModel(
      id: documentId,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      coverUrl: map['coverUrl'],
      album: map['album'],
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  /// Construit une piste depuis une réponse de l'API iTunes Search
  factory TrackModel.fromItunes(Map<String, dynamic> json) {
    final id = (json['trackId'] ?? json['collectionId'] ?? 0).toString();
    final cover = (json['artworkUrl100'] as String?)?.replaceAll(
      '100x100',
      '600x600',
    );
    final ms = (json['trackTimeMillis'] as num?)?.toInt() ?? 0;
    return TrackModel(
      id: id,
      title: json['trackName'] as String? ?? 'Titre inconnu',
      artist: json['artistName'] as String? ?? 'Artiste inconnu',
      audioUrl: json['previewUrl'] as String? ?? '',
      coverUrl: cover,
      album: json['collectionName'] as String?,
      durationSeconds: ms > 0 ? (ms / 1000).round() : 0,
    );
  }

  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    String? coverUrl,
    String? album,
    int? durationSeconds,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      album: album ?? this.album,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TrackModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
