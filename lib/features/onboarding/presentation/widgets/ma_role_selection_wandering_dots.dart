import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';

/// Role Selection only. The shared onboarding dot grid and Splash stay static.
class MaRoleSelectionWanderingDots extends StatelessWidget {
  const MaRoleSelectionWanderingDots({
    super.key,
    required this.progress,
  });

  /// Runs from 0 to 1 over five seconds, after one stationary second.
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

class _DotPath {
  const _DotPath({
    required this.first,
    required this.second,
    required this.firstSecond,
    required this.secondSecond,
  });

  final Offset first;
  final Offset second;
  final double firstSecond;
  final double secondSecond;
}

/// Each dot follows its OWN seeded, non-periodic route and timing. No
/// row/column phase, shared oscillation, ripple, or grid-wide wave.
abstract final class MaRoleSelectionDotMotion {
  static const double durationSeconds = 5;

  static Offset _randomTarget(math.Random random, double minimum, double range) {
    final angle = random.nextDouble() * math.pi * 2;
    final distance = minimum + random.nextDouble() * range;
    return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
  }

  static final List<_DotPath> _paths = List<_DotPath>.generate(
    MaDotGridMetrics.rows * MaDotGridMetrics.columns,
    (index) {
      final random = math.Random(0x4D41 + index * 7919);
      return _DotPath(
        first: _randomTarget(random, 4, 3),
        second: _randomTarget(random, 2.5, 3.5),
        // Each dot changes direction at different times; unlike a shared
        // outward/return envelope, the grid never moves as one wave.
        firstSecond: (1.6 + random.nextDouble() * 1.2) * 5 / 7,
        secondSecond: (3.4 + random.nextDouble() * 1.6) * 5 / 7,
      );
    },
    growable: false,
  );

  static double _ease(double fraction) =>
      Curves.easeInOutSine.transform(fraction);

  /// animationSeconds: 0 at screen second 1; 5 at screen second 6.
  /// All offsets are EXACTLY zero before and after the five-second motion.
  static Offset displacement({
    required int row,
    required int column,
    required double animationSeconds,
  }) {
    if (animationSeconds <= 0 || animationSeconds >= durationSeconds) {
      return Offset.zero;
    }

    final path = _paths[row * MaDotGridMetrics.columns + column];
    if (animationSeconds < path.firstSecond) {
      return Offset.lerp(
        Offset.zero,
        path.first,
        _ease(animationSeconds / path.firstSecond),
      )!;
    }
    if (animationSeconds < path.secondSecond) {
      return Offset.lerp(
        path.first,
        path.second,
        _ease(
          (animationSeconds - path.firstSecond) /
              (path.secondSecond - path.firstSecond),
        ),
      )!;
    }
    return Offset.lerp(
      path.second,
      Offset.zero,
      _ease(
        (animationSeconds - path.secondSecond) /
            (durationSeconds - path.secondSecond),
      ),
    )!;
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
  bool shouldRepaint(covariant MaRoleSelectionWanderingDotsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
