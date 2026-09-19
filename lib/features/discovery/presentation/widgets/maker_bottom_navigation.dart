import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_svg_asset.dart';

class MakerBottomNavigation extends StatelessWidget {
  const MakerBottomNavigation({
    super.key,
    this.selectedColumnCount = 2,
    this.heartSelected = false,
    this.settingsSelected = false,
    this.onSavedTap,
    this.onColumnCountSelected,
    this.onSettingsTap,
    this.settingsSemanticsLabel = 'Maker settings',
  });

  final int selectedColumnCount;
  final bool heartSelected;
  final bool settingsSelected;
  final VoidCallback? onSavedTap;
  final ValueChanged<int>? onColumnCountSelected;
  final VoidCallback? onSettingsTap;
  final String settingsSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 430).clamp(0.86, 1.10);
        final barHeight = (65 * scale).clamp(58.0, 72.0).toDouble();
        final iconSize = (18 * scale).clamp(18.0, 20.0).toDouble();

        return Material(
          key: const Key('maker_bottom_navigation_material'),
          color: AppColors.artworkNavBackground,
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
                  for (var columnCount = 1; columnCount <= 4; columnCount++)
                    Expanded(
                      child: _ColumnCountItem(
                        columnCount: columnCount,
                        selected: columnCount == selectedColumnCount,
                        onTap: () => onColumnCountSelected?.call(columnCount),
                      ),
                    ),
                  Expanded(
                    child: _SvgNavigationItem(
                      itemKey: const Key('maker_nav_settings'),
                      iconKey: const Key('maker_nav_settings_svg'),
                      assetName: 'assets/setting.svg',
                      fallbackAssetName: 'assets/icons/setting.svg',
                      semanticsLabel: settingsSemanticsLabel,
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

class _ColumnCountItem extends StatelessWidget {
  const _ColumnCountItem({
    required this.columnCount,
    required this.selected,
    required this.onTap,
  });

  final int columnCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$columnCount artwork columns',
      child: InkResponse(
        key: Key('maker_nav_$columnCount'),
        onTap: onTap,
        radius: 28,
        child: Center(
          child: Text(
            '$columnCount',
            key: Key('maker_nav_column_text_$columnCount'),
            style: TextStyle(
              fontFamily: 'HelveticaNeueLTStd',
              fontSize: selected ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.50),
            ),
          ),
        ),
      ),
    );
  }
}
