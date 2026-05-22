import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listening_session_model.dart';

/// Agrégat de minutes écoutées sur les 7 derniers jours
class WeeklyListeningStats {
  /// 7 entrées du plus ancien au plus récent (index 0 = il y a 6 jours, 6 = aujourd'hui)
  final List<DailyMinutes> days;
  final int totalMinutes;

  const WeeklyListeningStats({required this.days, required this.totalMinutes});

  factory WeeklyListeningStats.empty() {
    final now = DateTime.now();
    final days = List<DailyMinutes>.generate(7, (i) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      return DailyMinutes(date: d, minutes: 0);
    });
    return WeeklyListeningStats(days: days, totalMinutes: 0);
  }
}

class DailyMinutes {
  final DateTime date;
  final int minutes;
  const DailyMinutes({required this.date, required this.minutes});
}

class ArtistMinutes {
  final String artist;
  final int minutes;
  const ArtistMinutes({required this.artist, required this.minutes});
}

/// Service gérant l'enregistrement et l'agrégation des statistiques d'écoute
class ListeningStatsService {
  final FirebaseFirestore _firestore;

  ListeningStatsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsCol(String uid) {
    return _firestore.collection('users').doc(uid).collection('sessions');
  }

  /// Enregistre une session d'écoute (ignorée si < 5 secondes pour limiter le bruit).
  Future<void> logSession({
    required String uid,
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    required int listenedSeconds,
  }) async {
    if (uid.isEmpty || trackId.isEmpty || listenedSeconds < 5) return;
    final session = ListeningSessionModel(
      id: '',
      trackId: trackId,
      trackTitle: trackTitle,
      trackArtist: trackArtist,
      listenedSeconds: listenedSeconds,
      listenedAt: DateTime.now(),
    );
    await _sessionsCol(uid).add(session.toMap());
  }

  /// Récupère les sessions d'un mois donné (YYYY-MM).
  Future<List<ListeningSessionModel>> getSessionsForMonth(
    String uid,
    DateTime month,
  ) async {
    if (uid.isEmpty) return const [];
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final snap = await _sessionsCol(uid)
        .where('listenedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('listenedAt', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs
        .map((d) => ListeningSessionModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stats des 7 derniers jours, agrégées en minutes par jour.
  Future<WeeklyListeningStats> getWeeklyStats(String uid) async {
    if (uid.isEmpty) return WeeklyListeningStats.empty();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    final snap = await _sessionsCol(uid)
        .where('listenedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    // Bucket par jour
    final Map<String, int> bucketSeconds = {};
    for (final doc in snap.docs) {
      final s = ListeningSessionModel.fromMap(doc.data(), doc.id);
      final dKey =
          '${s.listenedAt.year}-${s.listenedAt.month}-${s.listenedAt.day}';
      bucketSeconds[dKey] = (bucketSeconds[dKey] ?? 0) + s.listenedSeconds;
    }

    final days = List<DailyMinutes>.generate(7, (i) {
      final d = start.add(Duration(days: i));
      final key = '${d.year}-${d.month}-${d.day}';
      final mins = ((bucketSeconds[key] ?? 0) / 60).round();
      return DailyMinutes(date: d, minutes: mins);
    });

    final total = days.fold<int>(0, (a, b) => a + b.minutes);
    return WeeklyListeningStats(days: days, totalMinutes: total);
  }

  /// Top artistes (par minutes écoutées) sur les 30 derniers jours.
  Future<List<ArtistMinutes>> getTopArtists(String uid, {int limit = 5}) async {
    if (uid.isEmpty) return const [];
    final start = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _sessionsCol(uid)
        .where('listenedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final Map<String, int> bucket = {};
    for (final d in snap.docs) {
      final s = ListeningSessionModel.fromMap(d.data(), d.id);
      if (s.trackArtist.isEmpty) continue;
      bucket[s.trackArtist] = (bucket[s.trackArtist] ?? 0) + s.listenedSeconds;
    }

    final list =
        bucket.entries
            .map(
              (e) =>
                  ArtistMinutes(artist: e.key, minutes: (e.value / 60).round()),
            )
            .where((a) => a.minutes > 0)
            .toList()
          ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return list.take(limit).toList();
  }

  /// Minutes totales écoutées sur le mois courant.
  Future<int> getCurrentMonthMinutes(String uid) async {
    if (uid.isEmpty) return 0;
    final sessions = await getSessionsForMonth(uid, DateTime.now());
    final totalSec = sessions.fold<int>(0, (a, s) => a + s.listenedSeconds);
    return (totalSec / 60).round();
  }
}
