// ════════════════════════════════════════
// lib/services/audio_player_service.dart
// ════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/track_model.dart';
import 'listening_stats_service.dart';

/// Service centralisant la logique du lecteur audio.
///
/// - Lecture en arrière-plan via [just_audio_background] (mobile/desktop)
/// - File d'attente gérée avec [ConcatenatingAudioSource]
/// - Journalisation automatique des sessions d'écoute >= 5s vers Firestore
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final ListeningStatsService _statsService;

  /// Identifiant utilisateur courant (mis à jour à la connexion).
  String? _userId;

  /// File d'attente courante (synchronisée avec _audioSource).
  List<TrackModel> _queue = [];

  /// Indices et durées pour calculer les sessions à logger.
  int _currentIndex = 0;
  int _accumulatedSecondsForCurrent = 0;
  DateTime? _lastPositionUpdate;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;

  AudioPlayerService({ListeningStatsService? statsService})
    : _statsService = statsService ?? ListeningStatsService() {
    _attachListeners();
  }

  // ─── Getters publics ─────────────────────────────────────────────

  AudioPlayer get player => _player;
  List<TrackModel> get queue => List.unmodifiable(_queue);
  TrackModel? get currentTrack =>
      (_queue.isNotEmpty && _currentIndex < _queue.length)
      ? _queue[_currentIndex]
      : null;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get playingStream => _player.playingStream;

  // ─── Configuration utilisateur ──────────────────────────────────

  void setUserId(String? uid) {
    // À chaque changement d'utilisateur, on flush la session courante
    _flushCurrentSession();
    _userId = uid;
  }

  // ─── Gestion de la file d'attente ───────────────────────────────

  /// Remplace la file d'attente et démarre la lecture à [startIndex].
  Future<void> setQueue(List<TrackModel> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _flushCurrentSession();

    _queue = List.of(tracks);
    final safeStart = startIndex.clamp(0, tracks.length - 1);
    _currentIndex = safeStart;
    _accumulatedSecondsForCurrent = 0;

    final sources = tracks
        .where((t) => t.audioUrl.isNotEmpty)
        .map(_toAudioSource)
        .toList();

    if (sources.isEmpty) return;

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: safeStart,
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (_) {
      // Erreur de chargement : on garde la queue mais on ne lance pas
    }
  }

  /// Lance la lecture d'une seule piste (remplace la file).
  Future<void> playSingle(TrackModel track) => setQueue([track]);

  // ─── Contrôles de lecture ──────────────────────────────────────

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() async {
    _flushCurrentSession();
    await _player.stop();
  }

  Future<void> next() async {
    if (_player.hasNext) {
      _flushCurrentSession();
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      _flushCurrentSession();
      await _player.seekToPrevious();
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  // ─── Conversion TrackModel → AudioSource ────────────────────────

  AudioSource _toAudioSource(TrackModel t) {
    // MediaItem pour l'affichage dans la notification / contrôle système.
    final tag = MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      artUri: (t.coverUrl != null && t.coverUrl!.isNotEmpty)
          ? Uri.tryParse(t.coverUrl!)
          : null,
      duration: t.durationSeconds > 0
          ? Duration(seconds: t.durationSeconds)
          : null,
    );
    return AudioSource.uri(Uri.parse(t.audioUrl), tag: tag);
  }

  // ─── Journalisation des sessions ────────────────────────────────

  void _attachListeners() {
    // Met à jour le compteur de secondes écoutées (uniquement quand le player joue)
    _positionSub = _player.positionStream.listen((pos) {
      if (!_player.playing) {
        _lastPositionUpdate = null;
        return;
      }
      final now = DateTime.now();
      if (_lastPositionUpdate != null) {
        final delta = now.difference(_lastPositionUpdate!).inMilliseconds;
        // On n'accumule pas si l'utilisateur a fait un seek (>1.5s d'écart)
        if (delta > 0 && delta < 1500) {
          _accumulatedSecondsForCurrent += (delta / 1000).round();
        }
      }
      _lastPositionUpdate = now;
    });

    // Détection du passage à la piste suivante
    _indexSub = _player.currentIndexStream.listen((newIndex) {
      if (newIndex == null) return;
      if (newIndex != _currentIndex) {
        _flushCurrentSession();
        _currentIndex = newIndex;
        _accumulatedSecondsForCurrent = 0;
      }
    });

    // Détection de la fin / arrêt → flush
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _flushCurrentSession();
      }
      if (!state.playing) {
        _lastPositionUpdate = null;
      }
    });
  }

  /// Envoie la session accumulée à Firestore puis remet à zéro.
  void _flushCurrentSession() {
    final uid = _userId;
    final track = currentTrack;
    final seconds = _accumulatedSecondsForCurrent;
    _accumulatedSecondsForCurrent = 0;
    _lastPositionUpdate = null;

    if (uid == null || uid.isEmpty || track == null || seconds < 5) return;

    // Fire-and-forget : on ne bloque pas l'UI
    _statsService.logSession(
      uid: uid,
      trackId: track.id,
      trackTitle: track.title,
      trackArtist: track.artist,
      listenedSeconds: seconds,
    );
  }

  /// À appeler avant la fermeture de l'application ou la déconnexion.
  Future<void> dispose() async {
    _flushCurrentSession();
    await _positionSub?.cancel();
    await _playerStateSub?.cancel();
    await _indexSub?.cancel();
    await _player.dispose();
  }

  /// Indique si la lecture en arrière-plan est disponible.
  bool get backgroundPlaybackSupported => !kIsWeb;
}
