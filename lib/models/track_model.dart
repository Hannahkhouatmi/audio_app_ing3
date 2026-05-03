class TrackModel {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String imageUrl;
  final String categoryId;

  TrackModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.imageUrl,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'audioUrl': audioUrl,
    'imageUrl': imageUrl,
    'categoryId': categoryId,
  };

  factory TrackModel.fromMap(Map<String, dynamic> map) => TrackModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    artist: map['artist'] ?? '',
    audioUrl: map['audioUrl'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    categoryId: map['categoryId'] ?? '',
  );
}
