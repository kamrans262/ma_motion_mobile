import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppButtonStyles {
  static ButtonStyle outlineAction({double borderWidth = 1.2}) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.pressed)
            ? AppColors.primary
            : AppColors.savedBackground;
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
          width: borderWidth,
        );
      }),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(),
      ),
    );
  }
}
