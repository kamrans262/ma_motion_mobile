import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';

/// Role Selection only. The shared onboarding dot grid and Splash stay static.
class MaRoleSelectionWanderingDots extends StatelessWidget {
  const MaRoleSelectionWanderingDots({super.key, required this.progress});

  /// Runs from 0 to 1 over six seconds, after one stationary second.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        key: const Key('role_selection_wandering_dots'),
        painter: MaRoleSelectionWanderingDotsPainter(progress: progress),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Each dot travels along one straight, independently seeded direction,
/// then reverses along that SAME line to its exact starting position.
/// There is no second destination, turn, oscillation, or shared grid motion.
abstract final class MaRoleSelectionDotMotion {
  static const double durationSeconds = 6;

  static final List<Offset> _targets = List<Offset>.generate(
    MaDotGridMetrics.rows * MaDotGridMetrics.columns,
    (index) {
      final random = math.Random(0x4D41 + index * 7919);
      final angle = random.nextDouble() * math.pi * 2;
      final distance = 4.0 + random.nextDouble() * 3.0;
      return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
    },
    growable: false,
  );

  // Slightly different turnaround times keep neighboring dots independent,
  // rather than making an outward-and-return wave across the grid.
  static final List<double> _turnaroundSeconds = List<double>.generate(
    MaDotGridMetrics.rows * MaDotGridMetrics.columns,
    (index) => 2.7 + math.Random(0x524F + index * 104729).nextDouble() * 0.6,
    growable: false,
  );

  static double _ease(double fraction) =>
      Curves.easeInOutSine.transform(fraction);

  /// Motion seconds 0–6 correspond to screen seconds 1–7. Only the distance
  /// changes: the direction is fixed for each dot until it reverses home.
  static Offset displacement({
    required int row,
    required int column,
    required double animationSeconds,
  }) {
    if (animationSeconds <= 0 || animationSeconds >= durationSeconds) {
      return Offset.zero;
    }

    final index = row * MaDotGridMetrics.columns + column;
    final turnaround = _turnaroundSeconds[index];
    final distanceFraction = animationSeconds <= turnaround
        ? _ease(animationSeconds / turnaround)
        : 1 -
              _ease(
                (animationSeconds - turnaround) /
                    (durationSeconds - turnaround),
              );
    return _targets[index] * distanceFraction;
  }
}

class MaRoleSelectionWanderingDotsPainter extends CustomPainter {
  MaRoleSelectionWanderingDotsPainter({required this.progress})
    : super(repaint: progress);

  final Animation<double> progress;

  double get animationSeconds =>
      progress.value * MaRoleSelectionDotMotion.durationSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    if (!MaDotGridMetrics.hasValidSize(size)) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final xSpacing = MaDotGridMetrics.horizontalSpacing(size);
    final ySpacing = MaDotGridMetrics.verticalSpacing(size);
    final seconds = animationSeconds;

    for (var row = 0; row < MaDotGridMetrics.rows; row++) {
      for (var column = 0; column < MaDotGridMetrics.columns; column++) {
        final origin = Offset(
          (column + 0.5) * xSpacing,
          (row + 0.5) * ySpacing,
        );
        canvas.drawCircle(
          origin +
              MaRoleSelectionDotMotion.displacement(
                row: row,
                column: column,
                animationSeconds: seconds,
              ),
          MaDotGridMetrics.dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant MaRoleSelectionWanderingDotsPainter oldDelegate,
  ) => oldDelegate.progress != progress;
}
