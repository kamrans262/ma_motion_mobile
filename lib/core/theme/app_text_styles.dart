import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String displayFontFamily = 'HelveticaNeueLTStd';
  static const String bodyFontFamily = 'Instrument Sans';

  // Keep the app's established shared typography unchanged. Instrument Sans
  // is opt-in only where a screen explicitly requests body copy in that font.
  static const String fontFamily = displayFontFamily;
  static const double bodyTracking = 0.2;

  static const TextStyle onboardingHeading = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    letterSpacing: -0.8,
    height: 1.22,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle onboardingHelper = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    letterSpacing: bodyTracking,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.mutedText,
  );

  static const TextStyle field = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    letterSpacing: bodyTracking,
    height: 1.0,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const TextStyle fieldHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    letterSpacing: bodyTracking,
    height: 1.0,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.normal,
    color: AppColors.mutedText,
  );

  static const TextStyle buttonDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    letterSpacing: bodyTracking,
    height: 1.0,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle buttonPurple = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    letterSpacing: bodyTracking,
    height: 1.0,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // Figma Type/Style selection copy is 14px throughout.
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    letterSpacing: bodyTracking,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle chipSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    letterSpacing: bodyTracking,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const TextStyle onboardingError = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    letterSpacing: bodyTracking,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const TextStyle error = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    letterSpacing: bodyTracking,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );
}
