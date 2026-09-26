import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared dot-grid geometry for the animated Splash and all existing
/// Maker/Appreciator onboarding backgrounds.
abstract final class MaDotGridMetrics {
  static const int columns = 18;
  static const int minimumRows = 36;
  static const double dotRadius = 0.8;

  static bool hasValidSize(Size size) =>
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0;

  /// Keep the established 18 columns across the full screen width. That
  /// width-derived cell size is reused vertically, so X/Y spacing is exactly
  /// equal and every grid cell is square.
  static double spacing(Size size) => size.width / columns;

  static double horizontalSpacing(Size size) => spacing(size);
  static double verticalSpacing(Size size) => spacing(size);

  /// Add as many rows as needed to cover the full screen height. Two extra
  /// rows keep the lattice extending past the top/bottom edges, so tall phones
  /// never show an empty band.
  static int rowCount(Size size) {
    if (!hasValidSize(size)) return minimumRows;
    final needed = (size.height / spacing(size)).ceil() + 2;
    return math.max(minimumRows, needed);
  }

  static Offset gridOrigin(Size size) {
    final cell = spacing(size);
    final rows = rowCount(size);
    return Offset(
      (size.width - (cell * columns)) / 2,
      (size.height - (cell * rows)) / 2,
    );
  }

  /// The dots are centered within square grid cells. Horizontal and vertical
  /// center-to-center spacing are identical, and the dynamically extended row
  /// count makes the pattern full-bleed on every supported screen.
  static void paintDots(Canvas canvas, Size size, Paint paint, double radius) {
    if (!hasValidSize(size) || !radius.isFinite || radius <= 0) return;

    final cell = spacing(size);
    final origin = gridOrigin(size);
    final rows = rowCount(size);

    for (var row = 0; row < rows; row++) {
      final y = origin.dy + ((row + 0.5) * cell);
      for (var column = 0; column < columns; column++) {
        final x = origin.dx + ((column + 0.5) * cell);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  /// A square lattice needs a half-cell diagonal radius to cover every point
  /// during the solid-purple opening before the circles shrink into dots.
  static double solidCircleRadius(Size size) {
    final halfCell = spacing(size) / 2;
    return math.sqrt((halfCell * halfCell) * 2);
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
