import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Arial';
  static const String instrumentSansFamily = 'Instrument Sans';
  static const String frauncesFamily = 'Fraunces';

  static const TextStyle onboardingHeading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle onboardingHelper = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
  );

  static const TextStyle field = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle fieldHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
  );

  static const TextStyle buttonDark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle buttonPurple = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Figma Type/Style selection copy is 14px throughout.
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
  );

  static const TextStyle chipSelected = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static const TextStyle error = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );
}
