import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.inputFormatters,
    this.maxLength,
    this.onSubmitted,
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
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onSubmitted: onSubmitted,
          // Center single-line input and hint text within the field.
          // Multiline input remains top-aligned so typing starts at the top.
          textAlignVertical: maxLines > 1
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          cursorColor: AppColors.primary,
          style: AppTextStyles.field,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.inputFill,
            hintText: hintText,
            hintStyle: AppTextStyles.fieldHint,
            counterText: '',
            // Shift single-line placeholders and entered text down by 2px
            // without changing total vertical padding or multiline fields.
            contentPadding: EdgeInsets.fromLTRB(
              20,
              maxLines > 1 ? 21 : 18,
              20,
              maxLines > 1 ? 11 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary50, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: errorText == null
                    ? AppColors.primary50
                    : AppColors.primary,
                width: 1.2,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            key: const Key('onboarding_field_error'),
            style: AppTextStyles.onboardingError,
          ),
        ],
      ],
    );
  }
}
