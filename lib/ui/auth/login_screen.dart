
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _showValidationStatus = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Charge l'email enregistré si l'option "Se souvenir de moi" était active.
  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('remembered_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  /// Connecte l'utilisateur et gère la persistance de l'option "Se souvenir de moi".
  Future<void> _login() async {
    setState(() {
      _showValidationStatus = true;
    });

    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      AppSnackBar.show(context, "Veuillez remplir tous les champs obligatoires.", SnackBarType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Gestion du "Se souvenir de moi"
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }

      if (mounted) {
        AppSnackBar.show(context, "Connexion réussie !", SnackBarType.success);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Un seul blob flou en haut à droite
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundBlobPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppSpacing.screenPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      // Row LOGO APP + NOM APP
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "Audio App",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        "Bon retour 👋",
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        "Connectez-vous pour continuer",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // FORMULAIRE
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
                        label: "Mot de passe",
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        showValidationStatus: _showValidationStatus,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Veuillez entrer votre mot de passe";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push(AppRoutes.resetPass);
                          },
                          child: Text(
                            "Mot de passe oublié ?",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // SE SOUVENIR DE MOI
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Switch(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            "Se souvenir de moi",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // BOUTON
                      AppButton.primary(
                        label: "Se connecter",
                        isFullWidth: true,
                        isLoading: _isLoading,
                        onPressed: _login,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // FOOTER
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.register);
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "Pas encore de compte ? ",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: "Créer un compte",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
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
