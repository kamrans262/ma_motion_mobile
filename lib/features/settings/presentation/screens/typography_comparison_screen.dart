import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_centered_taxonomy_label.dart';

/// Temporary, read-only typography comparison. Do not apply these styles to
/// onboarding, login, filter or settings until the design is selected.
class TypographyComparisonScreen extends StatelessWidget {
  const TypographyComparisonScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  // Chosen typography from the previous weight comparison (Variation 6):
  // Helvetica Neue LT Std, requested w800, with existing heading/title sizes.
  // The registered Helvetica file is w500; Flutter may synthesize w800.
  static const FontWeight _chosenWeight = FontWeight.w800;
  static const double _headingSize = 34;
  static const double _titleSize = 24;

  // Show the existing -0.5px heading tracking as a baseline, followed by
  // the requested 0–2px letter-spacing comparisons.
  static const List<double> _headingTracking = [
    -0.5, 0, 0.5, 1, 1.5, 2,
  ];
  static const List<double> _titleTracking = [
    0, 0.5, 1, 1.5, 2,
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
                  'Chosen font: Helvetica Neue LT Std, w800 (Variation 6). '
                  'Only Helvetica 65 Medium (w500) is registered, so w800 '
                  'is requested/simulated and may not look like a genuine '
                  'Helvetica Extra Bold file. Compare tracking below; '
                  'no changes will be made to the live app.',
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
                  'Selected: Helvetica · 34px · w800 (requested) · '
                  'line height 1.22. Current app tracking: -0.5px.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < _headingTracking.length; index++)
                  _variationTile(
                    index: index + 1,
                    tracking: _headingTracking[index],
                    sample: 'Welcome to the space between.',
                    isHeading: true,
                  ),
                const SizedBox(height: 16),
                _sectionTitle('Settings / Filter — Titles'),
                const SizedBox(height: 8),
                const Text(
                  'Selected: Helvetica · 24px · w800 (requested). '
                  'Current app tracking: default (approximately 0px).',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < _titleTracking.length; index++)
                  _variationTile(
                    index: index + 1,
                    tracking: _titleTracking[index],
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
    required double tracking,
    required String sample,
    required bool isHeading,
  }) {
    final fontSize = isHeading ? _headingSize : _titleSize;
    final referenceTracking = isHeading ? -0.5 : 0.0;
    final isCurrentTracking = tracking == referenceTracking;
    final trackingLabel = tracking > 0 ? '+' + tracking.toString() : tracking.toString();

    // Only the spacing changes between samples. All samples retain the
    // selected w800 and original app sizes, colors and heading line height.
    final previewStyle = isHeading
        ? AppTextStyles.onboardingHeading.copyWith(
            fontSize: fontSize,
            fontWeight: _chosenWeight,
            letterSpacing: tracking,
          )
        : TextStyle(
            fontFamily: AppTextStyles.displayFontFamily,
            fontSize: fontSize,
            fontWeight: _chosenWeight,
            letterSpacing: tracking,
            color: AppColors.primary,
          );

    return Container(
      key: Key(
        'typography_' +
            (isHeading ? 'heading_tracking_' : 'title_tracking_') +
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
            'Variation ' + index.toString() +
                ' — Letter spacing ' + trackingLabel + 'px' +
                (isCurrentTracking ? ' (Current app spacing)' : ''),
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Helvetica Neue LT Std · ' +
                fontSize.toStringAsFixed(0) +
                'px · w800 (requested) · tracking ' + trackingLabel + 'px' +
                (isHeading ? ' · line height 1.22' : ''),
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
