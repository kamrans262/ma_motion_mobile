import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.splashBackground,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.splashBackground,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x66904AFF),
        selectionHandleColor: AppColors.primary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            return states.contains(WidgetState.pressed)
                ? AppColors.primary
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.darkGray;
            }
            return states.contains(WidgetState.pressed)
                ? AppColors.white
                : AppColors.primary;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? AppColors.darkGray
                  : AppColors.primary,
              width: 1.2,
            );
          }),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(),
          ),
        ),
      ),
    );
  }
}
