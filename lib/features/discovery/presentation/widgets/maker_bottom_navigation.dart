import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MakerBottomNavigation extends StatelessWidget {
  const MakerBottomNavigation({
    super.key,
    this.selectedIndex = 2,
    this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      const Icon(Icons.favorite_border_rounded, size: 25),
      const Text('1'),
      const Text('2'),
      const Text('3'),
      const Text('4'),
      const Icon(Icons.settings_outlined, size: 25),
    ];

    return Material(
      color: const Color(0xFF0C2116),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List<Widget>.generate(items.length, (index) {
              final isSelected = index == selectedIndex;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: _semanticLabel(index),
                  child: InkResponse(
                    key: Key(_keyFor(index)),
                    onTap: () => onItemSelected?.call(index),
                    radius: 28,
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.70),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: isSelected ? 25 : 20,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.70),
                          ),
                          child: items[index],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static String _keyFor(int index) {
    return switch (index) {
      0 => 'maker_nav_saved',
      1 => 'maker_nav_1',
      2 => 'maker_nav_2',
      3 => 'maker_nav_3',
      4 => 'maker_nav_4',
      5 => 'maker_nav_settings',
      _ => 'maker_nav_$index',
    };
  }

  static String _semanticLabel(int index) {
    return switch (index) {
      0 => 'Saved',
      1 => 'Maker section 1',
      2 => 'Artwork discovery',
      3 => 'Maker section 3',
      4 => 'Maker section 4',
      5 => 'Settings',
      _ => 'Maker navigation',
    };
  }
}
