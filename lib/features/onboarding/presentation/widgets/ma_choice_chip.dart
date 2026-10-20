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
    this.fontFamily,
    this.selectedFontWeight,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    this.verticalOffset = MaCenteredTaxonomyLabel.opticalOffsetY,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedTextColor;
  final Color? unselectedBackgroundColor;
  // Opt-in font override for Settings without changing Onboarding.
  final String? fontFamily;
  // Only screens that opt in use a heavier selected label.
  final FontWeight? selectedFontWeight;
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
            border: Border.all(color: AppColors.primary, width: 1.1),
          ),
          child: MaCenteredTaxonomyLabel(
            label: label,
            verticalOffset: verticalOffset,
            style: selected
                ? AppTextStyles.chipSelected.copyWith(
                    fontFamily: fontFamily,
                    color: selectedTextColor,
                    fontWeight: selectedFontWeight,
                    fontSize: fontSize,
                    height: fontSize == 12 ? 16 / 12 : 1.1,
                  )
                : AppTextStyles.chip.copyWith(
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    height: fontSize == 12 ? 16 / 12 : 1.1,
                  ),
          ),
        ),
      ),
    );
  }
}
