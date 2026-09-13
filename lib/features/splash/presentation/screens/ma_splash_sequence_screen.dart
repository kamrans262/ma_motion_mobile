import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import '../../../auth/data/maker_entry_repository.dart';
import '../../../auth/domain/maker_entry_destination.dart';
import '../widgets/ma_full_logo.dart';

class MaSplashSequenceScreen extends ConsumerStatefulWidget {
  const MaSplashSequenceScreen({
    super.key,
    this.onResolved,
    this.entryResolver,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 12200),
  });

  final ValueChanged<MakerEntryDestination>? onResolved;
  final Future<MakerEntryDestination> Function()? entryResolver;
  final bool autoPlay;
  final Duration duration;

  @override
  ConsumerState<MaSplashSequenceScreen> createState() =>
      _MaSplashSequenceScreenState();
}

class _MaSplashSequenceScreenState extends ConsumerState<MaSplashSequenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _openingProgress;

  MakerEntryDestination? _resolvedDestination;
  bool _animationCompleted = false;
  bool _navigationSent = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    // The supplied reference is one continuous purple circle field:
    // initially the circles overlap enough to look like a solid screen, then
    // those same circles shrink until they become the final dot grid.
    _openingProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.081967,
        0.327869,
        curve: Curves.linear,
      ),
    );

    _controller.addStatusListener(_handleAnimationStatus);
    _resolveEntry();

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  Future<void> _resolveEntry() async {
    try {
      final resolver = widget.entryResolver;
      final destination = resolver != null
          ? await resolver()
          : await ref.read(makerEntryRepositoryProvider).restoreAppEntry();

      if (!mounted || _navigationSent) return;

      _resolvedDestination = destination;
      _navigateIfReady();
    } catch (_) {
      // Keep the final intro state visible if restoration cannot complete.
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    _animationCompleted = true;
    _navigateIfReady();
  }

  void _navigateIfReady() {
    if (!_animationCompleted ||
        _resolvedDestination == null ||
        _navigationSent ||
        !mounted) {
      return;
    }

    _navigationSent = true;
    widget.onResolved?.call(_resolvedDestination!);
  }

  double _logoOpacity(double value) {
    if (value < 0.588) return 1;
    if (value < 0.625) {
      final t = (value - 0.588) / (0.625 - 0.588);
      return 1 - Curves.easeInOutCubic.transform(t);
    }

    return 0;
  }

  double _welcomeOpacity(double value) {
    if (value < 0.618) return 0;

    if (value < 0.668) {
      final t = (value - 0.618) / (0.668 - 0.618);
      return Curves.easeOutCubic.transform(t);
    }

    if (value < 0.949 || _resolvedDestination == null) {
      return 1;
    }

    if (value < 0.988) {
      final t = (value - 0.949) / (0.988 - 0.949);
      return 1 - Curves.easeInCubic.transform(t);
    }

    return 0;
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ma_animated_splash'),
      backgroundColor: AppColors.splashBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ColoredBox(
            key: const Key('ma_splash_background'),
            color: AppColors.splashBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: IgnorePointer(
                    child: Opacity(
                      key: const Key('ma_splash_logo_opacity'),
                      opacity: _logoOpacity(_controller.value),
                      child: const MaFullLogo(),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    key: const Key('ma_splash_dot_pattern'),
                    painter: _ShrinkingDotFieldPainter(
                      progress: _openingProgress.value,
                    ),
                  ),
                ),
                SafeArea(
                  child: IgnorePointer(
                    child: Opacity(
                      key: const Key('ma_splash_welcome_opacity'),
                      opacity: _welcomeOpacity(_controller.value),
                      child: const _WelcomeMessage(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = (constraints.maxWidth * 0.074)
            .clamp(26.0, 34.0)
            .toDouble();
        final horizontal = (constraints.maxWidth * 0.12)
            .clamp(24.0, 56.0)
            .toDouble();

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Semantics(
              label: 'Welcome to MA. A place where art & design live.',
              child: Text(
                'Welcome to MA.\nA place where art &\ndesign live.',
                key: const Key('ma_splash_welcome_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Arial',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShrinkingDotFieldPainter extends CustomPainter {
  const _ShrinkingDotFieldPainter({required this.progress});

  final double progress;

  static const double _solidRadius = 0.70710678;
  static const double _finalDotRadius = 0.038;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final spacing = MaDotGridMetrics.spacingForWidth(size.width);
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (progress <= 0) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final smoothProgress = Curves.easeInOutSine.transform(clamped);
    final radiusFraction =
        _solidRadius + ((_finalDotRadius - _solidRadius) * smoothProgress);
    final radius = spacing * radiusFraction;

    final rows = (size.height / spacing).ceil() + 4;
    final columns = (size.width / spacing).ceil() + 4;

    for (var row = -2; row < rows; row++) {
      final y = row * spacing;

      for (var column = -2; column < columns; column++) {
        final x = column * spacing;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShrinkingDotFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
