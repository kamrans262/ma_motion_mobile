import 'package:flutter/material.dart';

import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MaOnboardingButton extends StatelessWidget {
  const MaOnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.subdued = false,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool subdued;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                disabledBackgroundColor: AppColors.primary50,
                disabledForegroundColor: AppColors.black,
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Text(label, style: AppTextStyles.buttonDark),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style:
                  OutlinedButton.styleFrom(
                    foregroundColor: subdued
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : AppColors.primary,
                    backgroundColor: AppColors.splashBackground,
                    side: BorderSide(
                      color: subdued
                          ? AppColors.primary.withValues(alpha: 0.55)
                          : AppColors.primary,
                      width: 1.2,
                    ),
                    shape: const RoundedRectangleBorder(),
                    padding: EdgeInsets.zero,
                  ).copyWith(
                    backgroundColor: AppButtonStyles.purpleWhenPressed(
                      AppColors.splashBackground,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.pressed)
                          ? AppColors.white
                          : subdued
                          ? AppColors.primary.withValues(alpha: 0.55)
                          : AppColors.primary,
                    ),
                  ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  letterSpacing: AppTextStyles.bodyTracking,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
    );
  }
}
