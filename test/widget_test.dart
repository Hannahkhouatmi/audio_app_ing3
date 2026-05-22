import 'package:flutter_test/flutter_test.dart';
import 'package:audio_app_ing3/models/track_model.dart';
import 'package:audio_app_ing3/models/monthly_goal_model.dart';

void main() {
  group('TrackModel Tests', () {
    test('formattedDuration returns correct mm:ss format', () {
      const track1 = TrackModel(
        id: '1',
        title: 'Song 1',
        artist: 'Artist 1',
        audioUrl: 'https://example.com/audio.mp3',
        durationSeconds: 125,
      );
      expect(track1.formattedDuration, '2:05');

      const track2 = TrackModel(
        id: '2',
        title: 'Song 2',
        artist: 'Artist 2',
        audioUrl: 'https://example.com/audio.mp3',
        durationSeconds: 0,
      );
      expect(track2.formattedDuration, '--:--');
    });

    test('fromItunes parses correct data', () {
      final json = {
        'trackId': 12345,
        'trackName': 'Itunes Track',
        'artistName': 'Itunes Artist',
        'previewUrl': 'https://example.com/preview.mp3',
        'artworkUrl100': 'https://example.com/100x100.jpg',
        'collectionName': 'Itunes Album',
        'trackTimeMillis': 180000,
      };

      final track = TrackModel.fromItunes(json);
      expect(track.id, '12345');
      expect(track.title, 'Itunes Track');
      expect(track.artist, 'Itunes Artist');
      expect(track.audioUrl, 'https://example.com/preview.mp3');
      expect(track.coverUrl, 'https://example.com/600x600.jpg');
      expect(track.album, 'Itunes Album');
      expect(track.durationSeconds, 180);
    });
  });

  group('MonthlyGoalModel Tests', () {
    test('progress calculates percentage correctly', () {
      final goal = MonthlyGoalModel(
        month: '2026-05',
        targetMinutes: 100,
        achievedMinutes: 45,
        updatedAt: DateTime.now(),
      );

      expect(goal.progress, 0.45);
      expect(goal.isAchieved, false);

      final achievedGoal = goal.copyWith(achievedMinutes: 110);
      expect(achievedGoal.progress, 1.0);
      expect(achievedGoal.isAchieved, true);
    });
  });
}
