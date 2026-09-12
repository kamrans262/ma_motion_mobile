import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_svg_asset.dart';

class MakerBottomNavigation extends StatelessWidget {
  const MakerBottomNavigation({
    super.key,
    this.selectedPage = 1,
    this.totalPages = 1,
    this.heartSelected = false,
    this.settingsSelected = false,
    this.onSavedTap,
    this.onPageSelected,
    this.onSettingsTap,
  });

  final int selectedPage;
  final int totalPages;
  final bool heartSelected;
  final bool settingsSelected;
  final VoidCallback? onSavedTap;
  final ValueChanged<int>? onPageSelected;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 430).clamp(0.86, 1.10);
        final barHeight = (65 * scale).clamp(58.0, 72.0).toDouble();
        final iconSize = (16 * scale).clamp(16.0, 18.0).toDouble();
        final visiblePages = _visiblePages(
          totalPages: totalPages,
          selectedPage: selectedPage,
        );

        return Material(
          color: const Color(0xFF0C2116),
          child: SafeArea(
            top: false,
            child: SizedBox(
              key: const Key('maker_bottom_navigation_surface'),
              height: barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _SvgNavigationItem(
                      itemKey: const Key('maker_nav_saved'),
                      iconKey: const Key('maker_nav_saved_svg'),
                      assetName: 'assets/heart.svg',
                      fallbackAssetName: 'assets/icons/heart.svg',
                      semanticsLabel: 'Saved artwork',
                      iconSize: iconSize,
                      selected: heartSelected,
                      onTap: onSavedTap,
                    ),
                  ),
                  for (final page in visiblePages)
                    Expanded(
                      child: _PageItem(
                        page: page,
                        selected: page == selectedPage,
                        scale: scale.toDouble(),
                        onTap: () => onPageSelected?.call(page),
                      ),
                    ),
                  Expanded(
                    child: _SvgNavigationItem(
                      itemKey: const Key('maker_nav_settings'),
                      iconKey: const Key('maker_nav_settings_svg'),
                      assetName: 'assets/setting.svg',
                      fallbackAssetName: 'assets/icons/setting.svg',
                      semanticsLabel: 'Maker settings',
                      iconSize: iconSize,
                      selected: settingsSelected,
                      onTap: onSettingsTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<int> _visiblePages({
    required int totalPages,
    required int selectedPage,
  }) {
    final safeTotal = totalPages < 1 ? 1 : totalPages;
    final safeSelected = selectedPage.clamp(1, safeTotal);

    if (safeTotal <= 4) {
      return List<int>.generate(safeTotal, (index) => index + 1);
    }

    var start = safeSelected - 1;
    if (start < 1) start = 1;
    if (start > safeTotal - 3) start = safeTotal - 3;

    return List<int>.generate(4, (index) => start + index);
  }
}

class _SvgNavigationItem extends StatelessWidget {
  const _SvgNavigationItem({
    required this.itemKey,
    required this.iconKey,
    required this.assetName,
    required this.fallbackAssetName,
    required this.semanticsLabel,
    required this.iconSize,
    required this.selected,
    required this.onTap,
  });

  final Key itemKey;
  final Key iconKey;
  final String assetName;
  final String fallbackAssetName;
  final String semanticsLabel;
  final double iconSize;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.78);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: InkResponse(
        key: itemKey,
        onTap: onTap,
        radius: 28,
        child: Center(
          child: SizedBox(
            key: iconKey,
            width: iconSize,
            height: iconSize,
            child: MaSvgAsset(
              assetName: assetName,
              fallbackAssetName: fallbackAssetName,
              fit: BoxFit.contain,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageItem extends StatelessWidget {
  const _PageItem({
    required this.page,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalSize = (20 * scale).clamp(18.0, 21.0).toDouble();
    final selectedSize = (25 * scale).clamp(22.0, 26.0).toDouble();

    return Semantics(
      button: true,
      selected: selected,
      label: 'Artwork page $page',
      child: InkResponse(
        key: Key('maker_nav_$page'),
        onTap: onTap,
        radius: 28,
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: selected ? selectedSize : normalSize,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.70),
            ),
          ),
        ),
      ),
    );
  }
}
