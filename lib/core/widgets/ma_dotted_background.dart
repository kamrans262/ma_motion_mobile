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

  /// Use one shared center-to-center distance on both axes so every dot sits
  /// inside a true square grid cell. The complete 18 × 36 grid is then
  /// centered inside the available surface.
  static double spacing(Size size) =>
      math.min(size.width / columns, size.height / rows);

  static double horizontalSpacing(Size size) => spacing(size);
  static double verticalSpacing(Size size) => spacing(size);

  static Offset gridOrigin(Size size) {
    final cell = spacing(size);
    return Offset(
      (size.width - (cell * columns)) / 2,
      (size.height - (cell * rows)) / 2,
    );
  }

  /// The dots are centered within square grid cells. Horizontal and vertical
  /// center-to-center spacing are therefore always identical.
  static void paintDots(Canvas canvas, Size size, Paint paint, double radius) {
    if (!hasValidSize(size) || !radius.isFinite || radius <= 0) return;

    final cell = spacing(size);
    final origin = gridOrigin(size);

    for (var row = 0; row < rows; row++) {
      final y = origin.dy + ((row + 0.5) * cell);
      for (var column = 0; column < columns; column++) {
        final x = origin.dx + ((column + 0.5) * cell);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  /// The opening circles cover the square grid cells plus any centered outer
  /// margin, preserving the continuous solid-purple Splash opening.
  static double solidCircleRadius(Size size) {
    final cell = spacing(size);
    final origin = gridOrigin(size);
    final halfWidth = origin.dx + (cell / 2);
    final halfHeight = origin.dy + (cell / 2);
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
