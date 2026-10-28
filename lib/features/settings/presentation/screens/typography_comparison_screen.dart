import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_centered_taxonomy_label.dart';

/// Temporary, read-only typography comparison. Do not apply these styles to
/// onboarding, login, filter or settings until the design is selected.
class TypographyComparisonScreen extends StatelessWidget {
  const TypographyComparisonScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  // The app's Figma-aligned onboarding token is 34px / w500 /
  // line height 1.22 / letter spacing -0.5px.
  // Settings/Filter reference: 24px / w500. Its line height and tracking
  // are not explicitly set in the current app reference.
  static const List<_TypeVariation> _headingVariations = [
    _TypeVariation(34, FontWeight.w500),
    _TypeVariation(33, FontWeight.w400),
    _TypeVariation(32, FontWeight.w500),
    _TypeVariation(30, FontWeight.w600),
    _TypeVariation(28, FontWeight.w400),
    _TypeVariation(35, FontWeight.w400),
    _TypeVariation(36, FontWeight.w500),
    _TypeVariation(38, FontWeight.w600),
    _TypeVariation(40, FontWeight.w500),
    _TypeVariation(42, FontWeight.w600),
  ];

  static const List<_TypeVariation> _titleVariations = [
    _TypeVariation(24, FontWeight.w500),
    _TypeVariation(23, FontWeight.w400),
    _TypeVariation(22, FontWeight.w500),
    _TypeVariation(21, FontWeight.w600),
    _TypeVariation(20, FontWeight.w400),
    _TypeVariation(25, FontWeight.w400),
    _TypeVariation(26, FontWeight.w500),
    _TypeVariation(28, FontWeight.w600),
    _TypeVariation(30, FontWeight.w500),
    _TypeVariation(32, FontWeight.w600),
  ];

  // Preview-only border opacity variations; leave Settings unchanged.
  static const List<int> _chipBorderPercentages = [
    30, 40, 50, 60, 70, 80, 90, 100,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('typography_comparison_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const Key('typography_comparison_scroll'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('typography_comparison_back'),
                      tooltip: 'Back',
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Typography Comparison',
                        style: TextStyle(
                          fontFamily: AppTextStyles.displayFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Helvetica Neue LT Std 65 Medium is the only registered '
                  'Helvetica font file. w500 is genuine; w400 and w600 are '
                  'requested/simulated weights, not separate font files. '
                  'They may render like w500 on some devices.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Onboarding / Animation / Login — Headings'),
                const SizedBox(height: 8),
                const Text(
                  'Reference: 34px · w500 · line height 1.22 · tracking -0.5px',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < _headingVariations.length; index++)
                  _variationTile(
                    index: index + 1,
                    variation: _headingVariations[index],
                    sample: 'Welcome to the space between.',
                    isHeading: true,
                  ),
                const SizedBox(height: 16),
                _sectionTitle('Settings / Filter — Titles'),
                const SizedBox(height: 8),
                const Text(
                  'Reference: 24px · w500 · default line height and tracking',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < _titleVariations.length; index++)
                  _variationTile(
                    index: index + 1,
                    variation: _titleVariations[index],
                    sample: 'Settings',
                    isHeading: false,
                  ),
                const SizedBox(height: 16),
                _sectionTitle('Settings Chips — Border Color Comparison'),
                const SizedBox(height: 8),
                const Text(
                  'Unselected Type/Style chips only. Same 12px w600 text, '
                  'background, padding, and spacing as Settings. Only the '
                  'purple border opacity varies from 30% to 100%. '
                  'The current Settings border remains 40%.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0;
                    index < _chipBorderPercentages.length;
                    index++)
                  _chipBorderVariationTile(
                    index: index + 1,
                    borderPercent: _chipBorderPercentages[index],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipBorderVariationTile({
    required int index,
    required int borderPercent,
  }) {
    final borderOpacity = borderPercent / 100.0;

    return Container(
      key: Key('typography_chips_border_$borderPercent'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.filterInputFill,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variation ' + index.toString() + ' — ' +
                borderPercent.toString() + '% Purple Border' +
                (borderPercent == 40 ? ' (Current Settings)' : ''),
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          _chipSampleLabel('Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _previewChip('Painting', borderOpacity),
              _previewChip('Sculpture', borderOpacity),
            ],
          ),
          const SizedBox(height: 16),
          _chipSampleLabel('Style'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _previewChip('Abstract', borderOpacity),
              _previewChip('Minimalist', borderOpacity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipSampleLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.onboardingHelper.copyWith(
        fontFamily: AppTextStyles.bodyFontFamily,
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // Uses the same unselected Settings chip fill, padding, text style and
  // taxonomy label alignment. Only the preview border alpha is varied.
  Widget _previewChip(String label, double borderOpacity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF020202),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: borderOpacity),
          width: 1.1,
        ),
      ),
      child: MaCenteredTaxonomyLabel(
        label: label,
        verticalOffset: 0,
        style: AppTextStyles.chip.copyWith(
          fontFamily: AppTextStyles.bodyFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 16 / 12,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: AppTextStyles.displayFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
    );
  }

  Widget _variationTile({
    required int index,
    required _TypeVariation variation,
    required String sample,
    required bool isHeading,
  }) {
    final isOriginal = index == 1;
    final simulated = variation.weight != FontWeight.w500;
    final weightLabel = variation.weight == FontWeight.w400
        ? 'w400'
        : variation.weight == FontWeight.w600
        ? 'w600'
        : 'w500';

    // Variation 1 of the heading section copies the actual shared text style;
    // no other screen or global theme is modified.
    final previewStyle = isHeading
        ? AppTextStyles.onboardingHeading.copyWith(
            fontSize: variation.size,
            fontWeight: variation.weight,
          )
        : TextStyle(
            fontFamily: AppTextStyles.displayFontFamily,
            fontSize: variation.size,
            fontWeight: variation.weight,
            color: AppColors.primary,
          );

    return Container(
      key: Key(
        'typography_' +
            (isHeading ? 'heading_' : 'title_') +
            index.toString(),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.filterInputFill,
        border: Border.all(color: AppColors.primary50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variation ' +
                index.toString() +
                (isOriginal ? ' — Figma Original' : ''),
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            variation.size.toStringAsFixed(0) +
                'px · ' +
                weightLabel +
                (simulated ? ' (simulated / requested)' : ' (genuine w500)'),
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sample,
            style: previewStyle,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}

class _TypeVariation {
  const _TypeVariation(this.size, this.weight);

  final double size;
  final FontWeight weight;
}
