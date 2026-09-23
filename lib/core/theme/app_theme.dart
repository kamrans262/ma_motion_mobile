import 'package:flutter/material.dart';

import 'app_button_styles.dart';
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
      // Purple button feedback replaces the default white circular ripple.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x669F67FF),
        selectionHandleColor: AppColors.primary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.outlineAction(),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: AppButtonStyles.purpleWhenPressed(
            Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.pressed)
                ? AppColors.white
                : AppColors.primary,
          ),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.pressed)
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
    );
  }
}
