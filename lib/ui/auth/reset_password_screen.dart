
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _showValidationStatus = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Tente d'envoyer l'email de réinitialisation de mot de passe.
  Future<void> _sendResetLink() async {
    setState(() {
      _showValidationStatus = true;
    });

    if (!_formKey.currentState!.validate()) {
      AppSnackBar.show(context, "Veuillez entrer une adresse email valide.", SnackBarType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());
      
      setState(() {
        _isSuccess = true;
      });
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
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isSuccess ? _buildSuccessState() : _buildInitialState(),
          ),
        ),
      ),
    );
  }

  /// Construit la vue d'état initial pour saisir l'email.
  Widget _buildInitialState() {
    return KeyedSubtree(
      key: const ValueKey('initial'),
      child: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentFaded,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 36,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  "Réinitialiser le mot de passe",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Entrez votre email. Vous recevrez un lien pour créer un nouveau mot de passe.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
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
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: "Envoyer le lien",
                  isFullWidth: true,
                  isLoading: _isLoading,
                  onPressed: _sendResetLink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la vue de confirmation d'envoi réussi.
  Widget _buildSuccessState() {
    return KeyedSubtree(
      key: const ValueKey('success'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.withOpacity(AppColors.success, 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.withOpacity(AppColors.success, 0.3)),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 36,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Email envoyé !",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Vérifiez votre boîte mail et suivez les instructions.",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.ghost(
              label: "Retour à la connexion",
              isFullWidth: true,
              onPressed: () {
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
