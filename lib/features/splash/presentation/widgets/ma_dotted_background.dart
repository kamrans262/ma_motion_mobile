import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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

  // Source Figma frame: 944 x 2048.
  static const double _referenceWidth = 944;
  static const double _referenceSpacing = 47.5;
  static const double _referenceStartX = 14;
  static const double _referenceRadius = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = size.width * (_referenceSpacing / _referenceWidth);
    final startX = size.width * (_referenceStartX / _referenceWidth);
    final radius = math.max(
      1.8,
      size.width * (_referenceRadius / _referenceWidth),
    );

    final paint = Paint()
      ..color = AppColors.splashDot
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    var row = 0;
    for (double y = 0; y <= size.height + spacing; y += spacing) {
      final stagger = row.isEven ? spacing / 2 : 0.0;

      for (
        double x = startX + stagger;
        x <= size.width + radius;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }

      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _MaDotGridPainter oldDelegate) => false;
}
