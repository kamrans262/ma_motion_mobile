import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';

/// Role Selection only: animates each existing grid dot without changing the
/// shared static onboarding background or the Splash animation.
class MaRoleSelectionWanderingDots extends StatelessWidget {
  const MaRoleSelectionWanderingDots({
    super.key,
    required this.progress,
  });

  /// Runs from 0 to 1 over five seconds, after a one-second stationary delay.
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

/// Deterministic, independent paths: every dot returns to its exact cell
/// center at animation seconds 0 and 5 (screen seconds 1 and 6).
abstract final class MaRoleSelectionDotMotion {
  static const double durationSeconds = 5;
  static const double outwardSeconds = 2;

  static final List<Offset> _wanderVectors = List<Offset>.generate(
    MaDotGridMetrics.rows * MaDotGridMetrics.columns,
    (index) {
      final row = index ~/ MaDotGridMetrics.columns;
      final column = index % MaDotGridMetrics.columns;
      final angle =
          ((row * 73 + column * 151 + 31) % 997) / 997 * math.pi * 2;
      // A few pixels beyond the reference's gentle wandering, while
      // remaining far smaller than the existing dot-to-dot spacing.
      final distance =
          4.0 + ((row * 67 + column * 37 + 17) % 101) / 101 * 3.0;
      return Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
    },
    growable: false,
  );

  /// Smoothly moves outward for 2 seconds, then returns over 3 seconds.
  static double envelopeAt(double animationSeconds) {
    if (animationSeconds <= 0 || animationSeconds >= durationSeconds) {
      return 0;
    }
    if (animationSeconds <= outwardSeconds) {
      return Curves.easeInOutSine.transform(
        animationSeconds / outwardSeconds,
      );
    }
    return 1 -
        Curves.easeInOutSine.transform(
          (animationSeconds - outwardSeconds) /
              (durationSeconds - outwardSeconds),
        );
  }

  static Offset displacement({
    required int row,
    required int column,
    required double animationSeconds,
  }) {
    final envelope = envelopeAt(animationSeconds);
    if (envelope == 0) return Offset.zero;

    final target = _wanderVectors[row * MaDotGridMetrics.columns + column];
    // Small sideways arc makes paths organic without introducing vibration.
    final arc = math.sin(math.pi * envelope) * 1.0;
    final magnitude = target.distance;
    return Offset(
      target.dx * envelope - target.dy / magnitude * arc,
      target.dy * envelope + target.dx / magnitude * arc,
    );
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
