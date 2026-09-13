import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ArtworkViewerDots extends StatelessWidget {
  const ArtworkViewerDots({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${currentIndex + 1} of $count',
      child: Row(
        key: const Key('artwork_viewer_dots'),
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(count, (index) {
          final active = index == currentIndex;

          return AnimatedContainer(
            key: Key('artwork_viewer_dot_$index'),
            duration: const Duration(milliseconds: 160),
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4.5),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : const Color(0xFF452080),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
