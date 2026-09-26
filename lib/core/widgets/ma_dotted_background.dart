import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared dot-grid geometry for the animated Splash and all existing
/// Maker/Appreciator onboarding backgrounds.
abstract final class MaDotGridMetrics {
  static const int columns = 18;
  static const int rows = 36;
  static const double dotRadius = 0.8;

  static bool hasValidSize(Size size) =>
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0;

  static double horizontalSpacing(Size size) => size.width / columns;
  static double verticalSpacing(Size size) => size.height / rows;

  /// The dots are centered within each grid cell. This keeps exactly 18
  /// columns and 36 rows visible, without cropped dots at the outer edges.
  static void paintDots(Canvas canvas, Size size, Paint paint, double radius) {
    if (!hasValidSize(size) || !radius.isFinite || radius <= 0) return;

    final horizontal = horizontalSpacing(size);
    final vertical = verticalSpacing(size);

    for (var row = 0; row < rows; row++) {
      final y = (row + 0.5) * vertical;
      for (var column = 0; column < columns; column++) {
        final x = (column + 0.5) * horizontal;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  /// The opening circles cover their entire grid cell before shrinking,
  /// preserving the continuous solid-purple opening of the Splash animation.
  static double solidCircleRadius(Size size) {
    final halfWidth = horizontalSpacing(size) / 2;
    final halfHeight = verticalSpacing(size) / 2;
    return math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight);
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
    if (!MaDotGridMetrics.hasValidSize(size)) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    MaDotGridMetrics.paintDots(canvas, size, paint, MaDotGridMetrics.dotRadius);
  }

  @override
  bool shouldRepaint(covariant _MaDotGridPainter oldDelegate) => false;
}
