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
  static const double durationSeconds = 6;

  static Offset _randomTarget(math.Random random, double minimum, double range) {
    final angle = random.nextDouble() * math.pi * 2;
    final distance = minimum + random.nextDouble() * range;
    return Offset(math.cos(angle) * distance, math.sin(angle) * distance);
  }

  static final List<_DotPath> _paths = List<_DotPath>.generate(
    MaDotGridMetrics.rows * MaDotGridMetrics.columns,
    (index) {
      final random = math.Random(0x4D41 + index * 7919);
      final first = _randomTarget(random, 4, 3);
      // One straight movement to the first point, then exactly one change
      // of direction to a second point, then a single return to origin.
      // The second leg has its own direction, not another radial pulse.
      final firstAngle = math.atan2(first.dy, first.dx);
      final turn = (random.nextBool() ? 1 : -1) *
          (math.pi * (0.45 + random.nextDouble() * 0.3));
      final secondAngle = firstAngle + turn;
      final secondDistance = 2.5 + random.nextDouble() * 2;
      final second = first +
          Offset(
            math.cos(secondAngle) * secondDistance,
            math.sin(secondAngle) * secondDistance,
          );
      return _DotPath(
        first: first,
        second: second,
        // Individual timing avoids a coordinated wave across the grid.
        firstSecond: 1.8 + random.nextDouble() * 0.4,
        secondSecond: 3.8 + random.nextDouble() * 0.4,
      );
    },
    growable: false,
  );

  static double _ease(double fraction) =>
      Curves.easeInOutSine.transform(fraction);

  /// animationSeconds: 0 at screen second 1; 6 at screen second 7.
  /// All offsets are EXACTLY zero before and after the six-second motion.
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
