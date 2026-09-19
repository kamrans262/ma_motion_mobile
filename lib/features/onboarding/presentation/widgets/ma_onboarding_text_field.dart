import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MaOnboardingTextField extends StatelessWidget {
  const MaOnboardingTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.autofillHints,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      autofillHints: autofillHints,
      cursorColor: AppColors.primary,
      style: AppTextStyles.field,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.inputFill,
        hintText: hintText,
        hintStyle: AppTextStyles.fieldHint,
        errorText: errorText,
        errorStyle: AppTextStyles.error,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: maxLines > 1 ? 16 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary50, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary50, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
    );
  }
}
