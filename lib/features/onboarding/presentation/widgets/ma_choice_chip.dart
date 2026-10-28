import 'package:flutter/material.dart';

import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_centered_taxonomy_label.dart';

class MaChoiceChip extends StatelessWidget {
  const MaChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedTextColor,
    this.unselectedBackgroundColor,
    this.unselectedBorderColor,
    this.fontFamily,
    this.selectedFontWeight,
    this.unselectedFontWeight,
    this.letterSpacing,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    this.verticalOffset = MaCenteredTaxonomyLabel.opticalOffsetY,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedTextColor;
  final Color? unselectedBackgroundColor;
  // Screen-specific outline for unselected chips only.
  final Color? unselectedBorderColor;
  // Opt-in font override for Settings without changing Onboarding.
  final String? fontFamily;
  // Only screens that opt in use a heavier selected label.
  final FontWeight? selectedFontWeight;
  // Optional weight for unselected chips; avoids changing Onboarding defaults.
  final FontWeight? unselectedFontWeight;
  // Optional tracking override for chips matched to the Filter popup.
  final double? letterSpacing;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        overlayColor: AppButtonStyles.purpleInkOverlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: padding,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : unselectedBackgroundColor ?? AppColors.savedBackground,
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : unselectedBorderColor ?? AppColors.primary,
              width: 1.1,
            ),
          ),
          child: MaCenteredTaxonomyLabel(
            label: label,
            verticalOffset: verticalOffset,
            stableSelectedFontWeight: selectedFontWeight,
            style: selected
                ? AppTextStyles.chipSelected.copyWith(
                    fontFamily: fontFamily,
                    color: selectedTextColor,
                    fontWeight: selectedFontWeight,
                    letterSpacing: letterSpacing,
                    fontSize: fontSize,
                    height: fontSize == 12 ? 16 / 12 : 1.1,
                  )
                : AppTextStyles.chip.copyWith(
                    fontFamily: fontFamily,
                    fontWeight: unselectedFontWeight,
                    letterSpacing: letterSpacing,
                    fontSize: fontSize,
                    height: fontSize == 12 ? 16 / 12 : 1.1,
                  ),
          ),
        ),
      ),
    );
  }
}
