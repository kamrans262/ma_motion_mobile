import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MaOnboardingButton extends StatelessWidget {
  const MaOnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Text(label, style: AppTextStyles.buttonPurple),
            ),
    );
  }
}
