import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class MaDotGridMetrics {
  static double spacingForWidth(double width) {
    if (!width.isFinite || width <= 0) return 18;

    return (width * 0.045).clamp(17.0, 24.0).toDouble();
  }

  static double radiusForWidth(double width) {
    if (!width.isFinite || width <= 0) return 0.8;

    return (spacingForWidth(width) * 0.038).clamp(0.7, 1.2).toDouble();
  }
}

class MaDottedBackground extends StatelessWidget {
  const MaDottedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _MaDotGridPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _MaDotGridPainter extends CustomPainter {
  const _MaDotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final spacing = MaDotGridMetrics.spacingForWidth(size.width);
    final radius = MaDotGridMetrics.radiusForWidth(size.width);

    if (!spacing.isFinite || spacing <= 0 || !radius.isFinite || radius <= 0) {
      return;
    }

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rowCount = math.max(1, (size.height / spacing).ceil() + 2);
    final columnCount = math.max(1, (size.width / spacing).ceil() + 2);

    // Keep the static screen on exactly the same grid phase as the final
    // frame of the shrinking-circle splash so there is no dot-grid jump.
    for (var row = -1; row < rowCount; row++) {
      final y = row * spacing;

      for (var column = -1; column < columnCount; column++) {
        final x = column * spacing;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaDotGridPainter oldDelegate) => false;
}
