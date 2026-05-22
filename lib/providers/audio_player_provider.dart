import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track_model.dart';
import '../services/audio_player_service.dart';
import 'auth_provider.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();

  // Synchronise l'UID utilisateur pour la journalisation des sessions
  ref.listen<AsyncValue<dynamic>>(currentUserProvider, (prev, next) {
    final user = next.value;
    service.setUserId(user?.uid);
  }, fireImmediately: true);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Piste actuellement jouée (suit currentIndexStream)
final currentTrackProvider = StreamProvider<TrackModel?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentIndexStream.map((_) => service.currentTrack);
});

/// True si le lecteur est en cours de lecture
final isPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioPlayerServiceProvider).playingStream;
});

/// État brut du player (loading / buffering / ready / completed)
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerServiceProvider).playerStateStream;
});

/// Position courante
final playerPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioPlayerServiceProvider).positionStream;
});

/// Durée totale de la piste
final playerDurationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioPlayerServiceProvider).durationStream;
});
