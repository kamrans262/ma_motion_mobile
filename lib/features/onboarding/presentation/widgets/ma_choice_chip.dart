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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.savedBackground,
            border: Border.all(color: AppColors.primary, width: 1.1),
          ),
          child: MaCenteredTaxonomyLabel(
            label: label,
            style: selected ? AppTextStyles.chipSelected : AppTextStyles.chip,
          ),
        ),
      ),
    );
  }
}
