import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

  static const double _referenceWidth = 944;
  static const double _referenceSpacing = 47.5;
  static const double _referenceStartX = 14;
  static const double _referenceRadius = 4;

  // Defensive lower bound so the painter can never enter a zero-step loop.
  static const double _minimumSpacing = 18;

  @override
  void paint(Canvas canvas, Size size) {
    // Flutter can briefly lay out/render a surface at 0x0 during Android
    // startup. Never derive loop increments from an empty/non-finite size.
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final scaledSpacing = size.width * (_referenceSpacing / _referenceWidth);

    final spacing = math.max(_minimumSpacing, scaledSpacing);

    if (!spacing.isFinite || spacing <= 0) {
      return;
    }

    final startX = size.width * (_referenceStartX / _referenceWidth);

    final radius = math.max(
      1.8,
      math.min(5.0, size.width * (_referenceRadius / _referenceWidth)),
    );

    final paint = Paint()
      ..color = AppColors.splashDot
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Use bounded integer counts instead of floating-point loop increments.
    // This guarantees termination even if future layout behavior changes.
    final rowCount = ((size.height + spacing) / spacing).ceil() + 1;
    final columnCount = ((size.width + spacing) / spacing).ceil() + 2;

    for (var row = 0; row < rowCount; row++) {
      final y = row * spacing;
      final stagger = row.isEven ? spacing / 2 : 0.0;

      for (var column = 0; column < columnCount; column++) {
        final x = startX + stagger + (column * spacing);

        if (x > size.width + radius) {
          break;
        }

        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaDotGridPainter oldDelegate) => false;
}
