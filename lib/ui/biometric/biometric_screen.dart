// ════════════════════════════════════════
// lib/ui/biometric/biometric_screen.dart
// ════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/shake_widget.dart';
import '../../services/biometric_service.dart';
import '../../providers/biometric_provider.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _secureStorage = const FlutterSecureStorage();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  bool _hasCheckedInit = false;
  String _statusText = "Authentification requise";
  Color _statusColor = AppColors.textDisabled;
  IconData _statusIcon = Icons.shield_outlined;

  Timer? _lockoutTimer;
  int _lockoutSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatusAndAuth();
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _audioPlayer.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Vérifie si l'utilisateur est déjà connecté ou s'il y a un lockout actif.
  Future<void> _checkStatusAndAuth() async {
    if (FirebaseAuth.instance.currentUser != null) {
      if (mounted) context.go(AppRoutes.stats);
      return;
    }

    // Charger l'état de lockout
    await _checkLockoutState();

    if (!_hasCheckedInit) {
      _hasCheckedInit = true;
      // Lance l'authentification automatique après 800ms si non verrouillé
      if (mounted && _lockoutSecondsRemaining <= 0) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _authenticate();
        });
      }
    }
  }

  /// Lit le stockage sécurisé pour vérifier la présence d'un lockout actif.
  Future<void> _checkLockoutState() async {
    final lockoutEndStr = await _secureStorage.read(key: 'biometric_lockout_end');
    if (lockoutEndStr != null) {
      final lockoutEndTime = DateTime.parse(lockoutEndStr);
      final now = DateTime.now();
      if (lockoutEndTime.isAfter(now)) {
        final diff = lockoutEndTime.difference(now).inSeconds;
        setState(() {
          _lockoutSecondsRemaining = diff;
          ref.read(biometricLockedProvider.notifier).state = true;
          _statusText = 'Réessayez dans ${_formatDuration(diff)}';
          _statusColor = AppColors.error;
          _statusIcon = Icons.warning_amber_rounded;
        });
        _startLockoutTimer();
      } else {
        await _clearLockout();
      }
    }
  }

  /// Démarre le timer de décompte du lockout.
  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        await _clearLockout();
      } else {
        setState(() {
          _lockoutSecondsRemaining--;
          _statusText = 'Réessayez dans ${_formatDuration(_lockoutSecondsRemaining)}';
        });
      }
    });
  }

  /// Efface le lockout et réinitialise le compteur.
  Future<void> _clearLockout() async {
    await _secureStorage.delete(key: 'biometric_lockout_end');
    ref.read(biometricLockedProvider.notifier).state = false;
    ref.read(biometricAttemptsProvider.notifier).state = 0;
    setState(() {
      _lockoutSecondsRemaining = 0;
      _statusText = "Authentification requise";
      _statusColor = AppColors.textDisabled;
      _statusIcon = Icons.shield_outlined;
    });
  }

  /// Déclenche le lockout temporaire de 2 minutes.
  Future<void> _triggerLockout() async {
    final lockoutEnd = DateTime.now().add(const Duration(minutes: 2));
    await _secureStorage.write(key: 'biometric_lockout_end', value: lockoutEnd.toIso8601String());
    ref.read(biometricLockedProvider.notifier).state = true;

    // Log lockout in Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('security_logs').add({
        'userId': user?.uid ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'biometric_lockout',
        'attempts': 5,
        'deviceInfo': 'Web/Mobile Client',
      });
    } catch (_) {}

    setState(() {
      _lockoutSecondsRemaining = 120;
      _statusText = 'Réessayez dans ${_formatDuration(120)}';
      _statusColor = AppColors.error;
      _statusIcon = Icons.warning_amber_rounded;
    });
    _startLockoutTimer();
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  /// Procède à la vérification biométrique.
  Future<void> _authenticate() async {
    if (_lockoutSecondsRemaining > 0) return;

    final service = ref.read(biometricServiceProvider);
    final res = await service.authenticate();

    if (!mounted) return;

    if (res == BiometricResult.success) {
      setState(() {
        _statusText = "Identité vérifiée";
        _statusColor = AppColors.success;
        _statusIcon = Icons.check_circle_outline_rounded;
      });

      // Jouer le son de succès
      try {
        await _audioPlayer.setAsset('assets/sounds/success.mp3');
        await _audioPlayer.play();
      } catch (_) {
        // En cas d'absence du fichier sonore success.mp3
      }

      // Navigation différée vers login
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) context.go(AppRoutes.login);
      });
    } else {
      // Secousse de l'icône biométrique en cas d'échec
      _shakeKey.currentState?.shake();

      if (res == BiometricResult.notEnrolled) {
        _showNotEnrolledDialog();
      } else if (res == BiometricResult.lockedOut ||
          res == BiometricResult.permanentlyLockedOut) {
        await _triggerLockout();
      } else {
        // Incrémenter les tentatives
        final currentAttempts = ref.read(biometricAttemptsProvider.notifier).state + 1;
        ref.read(biometricAttemptsProvider.notifier).state = currentAttempts;

        if (currentAttempts >= 5) {
          await _triggerLockout();
        } else {
          setState(() {
            _statusText = "Empreinte non reconnue";
            _statusColor = AppColors.error;
            _statusIcon = Icons.warning_amber_rounded;
          });
        }
      }
    }
  }

  /// Affiche le dialogue invitant à configurer une empreinte dans les réglages système.
  void _showNotEnrolledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.largeBR,
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            "Empreinte non configurée",
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            kIsWeb
                ? 'Configurez Windows Hello (empreinte, visage ou code PIN) dans Paramètres Windows > Comptes > Options de connexion, puis réessayez.'
                : 'Configurez une empreinte digitale dans les réglages de votre appareil pour continuer.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            AppButton.primary(
              label: 'Ouvrir les réglages',
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(biometricServiceProvider).openBiometricSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background blobs CustomPaint
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundBlobPainter(),
            ),
          ),
          // Contenu principal
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    // SECTION LOGO
                    ShakeWidget(
                      key: _shakeKey,
                      child: ScaleTransition(
                        scale: _breathingAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.accentFaded,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.fingerprint_outlined,
                            size: 48,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // SECTION TEXTE
                    Text(
                      "Vérification sécurisée",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      kIsWeb
                          ? 'Utilisez Windows Hello ou Touch ID'
                          : 'Utilisez votre empreinte digitale',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "pour accéder à l'application",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // SECTION STATUS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _statusIcon,
                          size: 16,
                          color: _statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: _statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    // SECTION BOUTONS
                    AppButton.primary(
                      label: "Scanner l'empreinte",
                      isFullWidth: true,
                      onPressed: _lockoutSecondsRemaining > 0 ? null : _authenticate,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () async {
                        if (kIsWeb) {
                          context.go(AppRoutes.login);
                          return;
                        }
                        await ref
                            .read(biometricServiceProvider)
                            .openBiometricSettings();
                      },
                      child: Text(
                        kIsWeb ? 'Passer à la connexion' : 'Utiliser un autre moyen',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre personnalisé pour afficher deux cercles flous subtils en arrière-plan.
class _BackgroundBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.withOpacity(AppColors.accent, 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(const Offset(40, 100), 100, paint1);

    final paint2 = Paint()
      ..color = AppColors.withOpacity(const Color(0xFF5B8DF6), 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width - 20, size.height - 120), 75, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
