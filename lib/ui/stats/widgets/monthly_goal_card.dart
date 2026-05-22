import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/loading_dots.dart';
import '../../../models/monthly_goal_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/stats_provider.dart';

/// Carte affichant l'objectif mensuel d'écoute avec un anneau de progression.
/// Permet de définir / modifier l'objectif via une boîte de dialogue.
class MonthlyGoalCard extends ConsumerWidget {
  const MonthlyGoalCard({super.key});

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    MonthlyGoalModel? existing,
  ) async {
    final controller = TextEditingController(
      text: existing?.targetMinutes.toString() ?? '',
    );

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeBR,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Objectif mensuel',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minutes d\'écoute visées pour le mois.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ex : 500',
                suffixText: 'min',
                suffixStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          AppButton.primary(
            label: 'Valider',
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v < 0 || v > 100000) {
                AppSnackBar.show(
                  ctx,
                  'Veuillez entrer un nombre valide (0 - 100000).',
                  SnackBarType.warning,
                );
                return;
              }
              Navigator.of(ctx).pop(v);
            },
          ),
        ],
      ),
    );

    if (result == null) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      await ref
          .read(monthlyGoalServiceProvider)
          .setGoal(uid: user.uid, targetMinutes: result);

      // Recalcule les minutes accomplies pour le mois en cours
      final achieved = await ref
          .read(listeningStatsServiceProvider)
          .getCurrentMonthMinutes(user.uid);
      await ref
          .read(monthlyGoalServiceProvider)
          .updateAchievedMinutes(uid: user.uid, achievedMinutes: achieved);

      ref.invalidate(currentMonthMinutesProvider);
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Objectif mis à jour !',
          SnackBarType.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Impossible de mettre à jour l\'objectif.',
          SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(currentMonthlyGoalProvider);
    final minutesAsync = ref.watch(currentMonthMinutesProvider);
    final monthLabel = DateFormat.MMMM(
      'fr_FR',
    ).format(DateTime.now()).toUpperCase();

    return AppCard(
      child: goalAsync.when(
        loading: () =>
            const SizedBox(height: 120, child: Center(child: LoadingDots())),
        error: (_, __) => _empty(context, ref, null),
        data: (goal) {
          if (goal == null || goal.targetMinutes == 0) {
            return _empty(context, ref, goal);
          }
          // On préfère les minutes courantes calculées en temps réel
          final achieved = minutesAsync.value ?? goal.achievedMinutes;
          final progress = goal.targetMinutes > 0
              ? (achieved / goal.targetMinutes).clamp(0.0, 1.0)
              : 0.0;
          final isAchieved = achieved >= goal.targetMinutes;

          return Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: _GoalRingPainter(
                          progress: progress,
                          color: isAchieved
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJECTIF $monthLabel',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: '$achieved',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: ' / ${goal.targetMinutes} min',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _editGoal(context, ref, goal),
                      child: Text(
                        'Modifier',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref, MonthlyGoalModel? goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aucun objectif défini',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fixez un objectif d\'écoute pour ce mois.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.primary(
          label: 'Définir un objectif',
          prefixIcon: Icons.flag_outlined,
          onPressed: () => _editGoal(context, ref, goal),
        ),
      ],
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _GoalRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    // Cercle de fond
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Arc de progression
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
