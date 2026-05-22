// ════════════════════════════════════════
// lib/core/widgets/app_text_field.dart
// ════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Champ de texte stylisé avec gestion d'état de validation.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showValidationStatus; // Affiche check/cross après soumission

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.showValidationStatus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de l'état de validation
    final text = widget.controller?.text ?? '';
    final errorText = widget.showValidationStatus ? widget.validator?.call(text) : null;
    final isValid = widget.showValidationStatus && errorText == null && text.isNotEmpty;
    final isInvalid = widget.showValidationStatus && errorText != null;

    // Construction de l'icône de suffixe
    Widget? trailing;
    if (widget.obscureText) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscureText = !_obscureText);
            },
          ),
          if (isValid)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            )
          else if (isInvalid)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
            ),
        ],
      );
    } else {
      if (isValid) {
        trailing = const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        );
      } else if (isInvalid) {
        trailing = const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
        );
      } else if (widget.suffixIcon != null) {
        trailing = widget.suffixIcon;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? AppColors.accent : AppColors.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: trailing,
            errorText: null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
      ],
    );
  }
}
