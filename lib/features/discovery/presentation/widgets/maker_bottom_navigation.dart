import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_svg_asset.dart';
import 'discovery_layout_metrics.dart';

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
        final metrics = DiscoveryLayoutMetrics.fromWidth(constraints.maxWidth);
        final iconSize = metrics.toolbarIconSize;
        // Keep outer icon edges aligned with Search and Filter. Aim for 50
        // logical pixels from each icon center to its adjacent number, while
        // fitting four independently tappable numbers on narrower screens.
        const sideItemWidth = 40.0;
        const toolbarButtonWidth = 48.0;
        const heartIconSize = 22.0;
        const filterIconSize = 24.0;
        // Align the bottom icons' outer bounds to the top toolbar's
        // Search and Filter icons at every supported screen width.
        final searchIconInsetWithinButton =
            (toolbarButtonWidth - iconSize) / 2;
        const filterIconInsetWithinButton =
            (toolbarButtonWidth - filterIconSize) / 2;
        final heartOffset =
            searchIconInsetWithinButton +
            heartIconSize / 2 -
            sideItemWidth / 2;
        final settingsOffset =
            sideItemWidth / 2 -
            iconSize / 2 -
            filterIconInsetWithinButton;
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = metrics.gridHorizontalPadding;
        final numberGroupWidth =
            screenWidth - 2 * horizontalPadding - 2 * sideItemWidth;
        final heartCenterX =
            horizontalPadding + searchIconInsetWithinButton + heartIconSize / 2;
        final settingsCenterX =
            screenWidth -
            horizontalPadding -
            filterIconInsetWithinButton -
            iconSize / 2;
        final iconCenterSpan = settingsCenterX - heartCenterX;

        // Reserve at least 40 logical pixels for each number's tap target
        // where screen width permits it. On very narrow widths the targets
        // shrink evenly rather than overflowing the Row.
        final minimumNumberWidth = (numberGroupWidth / 4)
            .clamp(0.0, 40.0)
            .toDouble();
        final maximumOuterGap =
            ((iconCenterSpan - 3 * minimumNumberWidth) / 2)
                .clamp(0.0, double.infinity)
                .toDouble();
        final outerGap = 50.0.clamp(0.0, maximumOuterGap).toDouble();
        final numberCenterSpacing = (iconCenterSpan - 2 * outerGap) / 3;
        final numberGroupLeftX = horizontalPadding + sideItemWidth;
        final numberGroupRightX = screenWidth - horizontalPadding - sideItemWidth;
        // Allow the number touch targets to contract on extremely small
        // screens without drifting the end numbers off their intended centers.
        final maxWidthAtLeftEdge =
            2 * (heartCenterX + outerGap - numberGroupLeftX);
        final maxWidthAtRightEdge =
            2 * (numberGroupRightX - (settingsCenterX - outerGap));
        final numberItemWidth = [
          48.0,
          numberCenterSpacing,
          maxWidthAtLeftEdge,
          maxWidthAtRightEdge,
        ].reduce((a, b) => a < b ? a : b).clamp(0.0, double.infinity).toDouble();
        final numberLeftInset =
            (heartCenterX + outerGap - numberGroupLeftX - numberItemWidth / 2)
                .clamp(0.0, double.infinity)
                .toDouble();
        final numberRightInset =
            (numberGroupRightX -
                    (settingsCenterX - outerGap) -
                    numberItemWidth / 2)
                .clamp(0.0, double.infinity)
                .toDouble();

        return Material(
          key: const Key('maker_bottom_navigation_material'),
          color: AppColors.artworkNavBackground,
          child: SafeArea(
            top: false,
            child: SizedBox(
              key: const Key('maker_bottom_navigation_surface'),
              height: barHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.gridHorizontalPadding,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: sideItemWidth,
                      child: _SvgNavigationItem(
                        itemKey: const Key('maker_nav_saved'),
                        iconKey: const Key('maker_nav_saved_svg'),
                        assetName: 'assets/heart.svg',
                        fallbackAssetName: 'assets/icons/heart.svg',
                        semanticsLabel: 'Saved artwork',
                        iconSize: heartIconSize,
                        horizontalVisualOffset: heartOffset,
                        selected: heartSelected,
                        filledHeart: heartSelected,
                        onTap: onSavedTap,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: numberLeftInset,
                          right: numberRightInset,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var columnCount = 1; columnCount <= 4; columnCount++)
                              SizedBox(
                                width: numberItemWidth,
                                child: _ColumnCountItem(
                                  columnCount: columnCount,
                                  selected: columnCount == selectedColumnCount,
                                  onTap: () =>
                                      onColumnCountSelected?.call(columnCount),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: sideItemWidth,
                      child: _SvgNavigationItem(
                        itemKey: const Key('maker_nav_settings'),
                        iconKey: const Key('maker_nav_settings_svg'),
                        assetName: 'assets/setting.svg',
                        fallbackAssetName: 'assets/icons/setting.svg',
                        semanticsLabel: settingsSemanticsLabel,
                        iconSize: iconSize,
                        horizontalVisualOffset: settingsOffset,
                        selected: settingsSelected,
                        onTap: onSettingsTap,
                      ),
                    ),
                  ],
                ),
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
    this.filledHeart = false,
    this.horizontalVisualOffset = 0,
    required this.onTap,
  });

  final Key itemKey;
  final Key iconKey;
  final String assetName;
  final String fallbackAssetName;
  final String semanticsLabel;
  final double iconSize;
  final bool selected;
  final bool filledHeart;
  final double horizontalVisualOffset;
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
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Center(
          // Adjust only the visual icon position, preserving tap targets
          // and the positions of numbers 1–4.
          child: Transform.translate(
            offset: Offset(horizontalVisualOffset, 0),
            child: SizedBox(
              key: iconKey,
              width: iconSize,
              height: iconSize,
              child: filledHeart
                  ? Icon(
                      Icons.favorite_rounded,
                      key: const Key('maker_nav_saved_filled'),
                      size: iconSize,
                      color: AppColors.primary,
                    )
                  : MaSvgAsset(
                      assetName: assetName,
                      fallbackAssetName: fallbackAssetName,
                      fit: BoxFit.contain,
                      color: color,
                    ),
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
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Center(
          // Helvetica Neue's numeral glyphs appear optically high when
          // mathematically centered beside the navigation icons.
          child: Transform.translate(
            offset: const Offset(0, 2),
            child: Text(
              '$columnCount',
              key: Key('maker_nav_column_text_$columnCount'),
              style: TextStyle(
                fontFamily: 'HelveticaNeueLTStd',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
