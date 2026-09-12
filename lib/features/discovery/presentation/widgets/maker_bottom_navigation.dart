import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MakerBottomNavigation extends StatelessWidget {
  const MakerBottomNavigation({
    super.key,
    this.selectedPage = 1,
    this.onPageSelected,
    this.onSettingsTap,
  });

  final int selectedPage;
  final ValueChanged<int>? onPageSelected;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C2116),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var page = 1; page <= 4; page++)
                Expanded(
                  child: _PageItem(
                    page: page,
                    selected: page == selectedPage,
                    onTap: () => onPageSelected?.call(page),
                  ),
                ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Maker settings',
                  child: InkResponse(
                    key: const Key('maker_nav_settings'),
                    onTap: onSettingsTap,
                    radius: 28,
                    child: Center(
                      child: Icon(
                        Icons.settings_outlined,
                        size: 25,
                        color: AppColors.primary.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              fontSize: selected ? 25 : 20,
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
