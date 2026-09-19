import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppButtonStyles {
  /// Keep the established idle color and border; use MA purple only
  /// while an action button is pressed.
  static WidgetStateProperty<Color> purpleWhenPressed(Color idleColor) {
    return WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.pressed)
          ? AppColors.primary
          : idleColor,
    );
  }

  /// Give non-ButtonStyle InkWell surfaces a purple pressed highlight
  /// without adding a white circular splash or changing their idle layout.
  static WidgetStateProperty<Color> get purpleInkOverlay {
    return WidgetStateProperty.resolveWith<Color>(
      (states) => states.contains(WidgetState.pressed)
          ? AppColors.primary.withValues(alpha: 0.25)
          : Colors.transparent,
    );
  }

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
