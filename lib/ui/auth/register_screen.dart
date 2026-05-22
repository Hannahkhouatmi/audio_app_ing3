// ════════════════════════════════════════
// lib/ui/auth/register_screen.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedBirthDate;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _showValidationStatus = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  /// Calcule en temps réel la force du mot de passe (0-100).
  void _checkPasswordStrength(String val) {
    int score = 0;
    if (val.length >= 8) score += 25;
    if (val.contains(RegExp(r'[A-Z]'))) score += 25;
    if (val.contains(RegExp(r'[0-9]'))) score += 25;
    if (val.contains(RegExp(r'[!@#\$&*~._-]'))) score += 25;

    setState(() {
      _passwordStrength = score;
    });
  }

  /// Calcule l'âge à partir de la date de naissance.
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Affiche le DatePicker avec les couleurs du design system.
  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd / MM / yyyy').format(picked);
      });
    }
  }

  /// Procède à la validation du formulaire et à l'inscription.
  Future<void> _register() async {
    setState(() {
      _showValidationStatus = true;
    });

    if (!_formKey.currentState!.validate()) {
      AppSnackBar.show(context, "Veuillez corriger les erreurs dans le formulaire.", SnackBarType.warning);
      return;
    }

    if (_selectedBirthDate == null) {
      AppSnackBar.show(context, "Veuillez indiquer votre date de naissance.", SnackBarType.warning);
      return;
    }

    if (_calculateAge(_selectedBirthDate!) < 13) {
      AppSnackBar.show(context, "Vous devez avoir au moins 13 ans pour créer un compte.", SnackBarType.error);
      return;
    }

    if (!_acceptTerms) {
      AppSnackBar.show(context, "Vous devez accepter les conditions d'utilisation.", SnackBarType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        birthDate: _selectedBirthDate!,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      if (mounted) {
        AppSnackBar.show(context, "Inscription réussie !", SnackBarType.success);
        context.go(AppRoutes.stats);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.toString().replaceAll("Exception: ", ""), SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcul des valeurs de la barre de force du mot de passe
    Color strengthColor;
    String strengthLabel;
    double strengthPercent;

    if (_passwordController.text.isEmpty) {
      strengthColor = AppColors.border;
      strengthLabel = "Saisissez un mot de passe";
      strengthPercent = 0.0;
    } else if (_passwordStrength <= 25) {
      strengthColor = AppColors.error;
      strengthLabel = 'Trop court';
      strengthPercent = 0.25;
    } else if (_passwordStrength == 50) {
      strengthColor = AppColors.warning;
      strengthLabel = "Faible";
      strengthPercent = 0.50;
    } else if (_passwordStrength == 75) {
      strengthColor = AppColors.accentLight;
      strengthLabel = "Bon";
      strengthPercent = 0.75;
    } else {
      strengthColor = AppColors.success;
      strengthLabel = "Fort";
      strengthPercent = 1.0;
    }

    final isTooYoung = _selectedBirthDate != null && _calculateAge(_selectedBirthDate!) < 13;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: AppRadius.mediumBR,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          "Créer un compte",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Blob flou en haut à droite
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundBlobPainter(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    // SECTION INFOS PERSONNELLES
                    Text(
                      "Informations personnelles",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: "Prénom",
                            controller: _firstNameController,
                            showValidationStatus: _showValidationStatus,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Requis";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            label: "Nom",
                            controller: _lastNameController,
                            showValidationStatus: _showValidationStatus,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Requis";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: "Adresse email",
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      showValidationStatus: _showValidationStatus,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez entrer votre adresse email";
                        }
                        final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegExp.hasMatch(value.trim())) {
                          return "Format d'email invalide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: "Téléphone (optionnel)",
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      showValidationStatus: _showValidationStatus,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        // Format algérien : 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX
                        final phoneRegExp = RegExp(r'^0[567]\d{8}$');
                        if (!phoneRegExp.hasMatch(value)) {
                          return "Format algérien invalide (ex: 0550123456)";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // SECTION SÉCURITÉ
                    Text(
                      "Sécurité",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: "Mot de passe",
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      showValidationStatus: _showValidationStatus,
                      onChanged: _checkPasswordStrength,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez saisir un mot de passe";
                        }
                        if (value.length < 8) {
                          return "Le mot de passe doit faire au moins 8 caractères";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // PASSWORD STRENGTH INDICATOR
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: strengthPercent,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strengthLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: strengthColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: "Confirmer le mot de passe",
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      showValidationStatus: _showValidationStatus,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez confirmer votre mot de passe";
                        }
                        if (value != _passwordController.text) {
                          return "Les mots de passe ne correspondent pas";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // SECTION DATE DE NAISSANCE
                    Text(
                      "Date de naissance",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: "JJ / MM / AAAA",
                      controller: _birthDateController,
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _selectBirthDate,
                      showValidationStatus: _showValidationStatus,
                      validator: (value) {
                        if (_selectedBirthDate == null) {
                          return "Veuillez sélectionner votre date de naissance";
                        }
                        return null;
                      },
                    ),
                    if (isTooYoung) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.withOpacity(AppColors.error, 0.1),
                          borderRadius: AppRadius.mediumBR,
                          border: Border.all(color: AppColors.withOpacity(AppColors.error, 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Vous devez avoir au moins 13 ans",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    // CONDITIONS
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (val) {
                              setState(() => _acceptTerms = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "J'accepte les ",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: "conditions d'utilisation",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // BOUTON
                    AppButton.primary(
                      label: "Créer mon compte",
                      isFullWidth: true,
                      isLoading: _isLoading,
                      onPressed: _register,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Déjà un compte ? ",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            "Se connecter",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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

/// Peintre personnalisé pour afficher un seul blob flou en haut à droite.
class _BackgroundBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.withOpacity(AppColors.accent, 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width - 20, 40), 125, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
