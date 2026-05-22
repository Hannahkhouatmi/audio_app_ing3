// ════════════════════════════════════════
// lib/providers/stats_provider.dart
// ════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/monthly_goal_model.dart';
import '../services/listening_stats_service.dart';
import '../services/monthly_goal_service.dart';
import 'auth_provider.dart';

/// Service singleton pour les statistiques.
final listeningStatsServiceProvider = Provider<ListeningStatsService>((ref) {
  return ListeningStatsService();
});

/// Service singleton pour les objectifs mensuels.
final monthlyGoalServiceProvider = Provider<MonthlyGoalService>((ref) {
  return MonthlyGoalService();
});

/// Statistiques hebdomadaires (7 derniers jours).
final weeklyStatsProvider = FutureProvider.autoDispose<WeeklyListeningStats>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return WeeklyListeningStats.empty();
  return ref.watch(listeningStatsServiceProvider).getWeeklyStats(user.uid);
});

/// Top artistes des 30 derniers jours.
final topArtistsProvider = FutureProvider.autoDispose<List<ArtistMinutes>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const [];
  return ref.watch(listeningStatsServiceProvider).getTopArtists(user.uid);
});

/// Minutes totales écoutées sur le mois courant (utilisé pour l'objectif).
final currentMonthMinutesProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;
  return ref
      .watch(listeningStatsServiceProvider)
      .getCurrentMonthMinutes(user.uid);
});

/// Objectif mensuel courant (flux temps réel).
final currentMonthlyGoalProvider =
    StreamProvider.autoDispose<MonthlyGoalModel?>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value(null);
      return ref.watch(monthlyGoalServiceProvider).watchCurrentGoal(user.uid);
    });
