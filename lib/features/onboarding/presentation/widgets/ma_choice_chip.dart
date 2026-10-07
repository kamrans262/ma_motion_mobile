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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedTextColor;
  final Color? unselectedBackgroundColor;

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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : unselectedBackgroundColor ?? AppColors.savedBackground,
            border: Border.all(color: AppColors.primary, width: 1.1),
          ),
          child: MaCenteredTaxonomyLabel(
            label: label,
            style: selected
                ? AppTextStyles.chipSelected.copyWith(
                    color: selectedTextColor,
                    fontSize: 14,
                    height: 1.1,
                  )
                : AppTextStyles.chip.copyWith(
                    fontSize: 14,
                    height: 1.1,
                  ),
          ),
        ),
      ),
    );
  }
}
