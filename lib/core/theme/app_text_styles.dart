import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'HelveticaNeueLTStd';
  // Slightly looser typography for the new font asset across shared styles.
  static const double bodyTracking = 0.2;

  static const TextStyle onboardingHeading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    letterSpacing: -0.5,
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
    fontStyle: FontStyle.italic,
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
