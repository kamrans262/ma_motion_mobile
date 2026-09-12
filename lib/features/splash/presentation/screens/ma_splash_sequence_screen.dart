import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/maker_entry_repository.dart';
import '../../../auth/domain/maker_entry_destination.dart';
import '../widgets/ma_full_logo.dart';

class MaSplashSequenceScreen extends ConsumerStatefulWidget {
  const MaSplashSequenceScreen({
    super.key,
    this.onResolved,
    this.entryResolver,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 5200),
  });

  final ValueChanged<MakerEntryDestination>? onResolved;
  final Future<MakerEntryDestination> Function()? entryResolver;
  final bool autoPlay;
  final Duration duration;

  @override
  ConsumerState<MaSplashSequenceScreen> createState() =>
      _MaSplashSequenceScreenState();
}

class _MaSplashSequenceScreenState
    extends ConsumerState<MaSplashSequenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundProgress;
  late final Animation<double> _dotProgress;
  late final Animation<double> _logoScale;
  late final Animation<double> _welcomeOpacity;
  late final Animation<Offset> _welcomeSlide;

  MakerEntryDestination? _resolvedDestination;
  bool _animationCompleted = false;
  bool _navigationSent = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _backgroundProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.07, 0.42, curve: Curves.easeInOutCubic),
    );

    _dotProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.56, curve: Curves.easeInOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.44, curve: Curves.easeOutBack),
      ),
    );

    _welcomeOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.88, curve: Curves.easeOutCubic),
    );

    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.90, curve: Curves.easeOutCubic),
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
      // Keep the final intro frame visible if session restoration cannot
      // complete. No secondary loading screen is introduced.
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
    if (value < 0.22) return 0;
    if (value < 0.36) {
      return Curves.easeOutCubic.transform((value - 0.22) / 0.14);
    }
    if (value < 0.66) return 1;
    if (value < 0.78) {
      return 1 -
          Curves.easeInCubic.transform((value - 0.66) / 0.12);
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final backgroundColor = Color.lerp(
            AppColors.primary,
            AppColors.splashBackground,
            _backgroundProgress.value,
          )!;

          return ColoredBox(
            key: const Key('ma_splash_background'),
            color: backgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    key: const Key('ma_splash_dot_pattern'),
                    painter: _AnimatedDotGridPainter(
                      progress: _dotProgress.value,
                    ),
                  ),
                ),
                SafeArea(
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: Opacity(
                          key: const Key('ma_splash_logo_opacity'),
                          opacity: _logoOpacity(_controller.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: const MaFullLogo(),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: FractionalTranslation(
                          translation: _welcomeSlide.value,
                          child: Opacity(
                            key: const Key('ma_splash_welcome_opacity'),
                            opacity: _welcomeOpacity.value,
                            child: const _WelcomeMessage(),
                          ),
                        ),
                      ),
                    ],
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

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: math.max(24, constraints.maxWidth * 0.12),
            ),
            child: const Semantics(
              label: 'Welcome to MA. A place where art & design live.',
              child: _WelcomeText(),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    final constraints = context.findRenderObject();

    return LayoutBuilder(
      builder: (context, box) {
        final fontSize = (box.maxWidth * 0.095)
            .clamp(26.0, 34.0)
            .toDouble();

        return Text(
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
        );
      },
    );
  }
}

class _AnimatedDotGridPainter extends CustomPainter {
  const _AnimatedDotGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.isEmpty) {
      return;
    }

    final spacing = (size.width * 0.045).clamp(17.0, 24.0).toDouble();
    final baseRadius = (size.width * 0.0042).clamp(1.2, 2.1).toDouble();
    final largeRadius = spacing * 0.44;

    double radius;
    Color color;

    if (progress < 0.36) {
      final t = progress / 0.36;
      radius = baseRadius * Curves.easeOut.transform(t);
      color = AppColors.splashBackground.withValues(alpha: 0.24);
    } else if (progress < 0.62) {
      final t = (progress - 0.36) / 0.26;
      radius = baseRadius + ((largeRadius - baseRadius) * t);
      color = Color.lerp(
        AppColors.splashBackground.withValues(alpha: 0.32),
        AppColors.primary,
        t,
      )!;
    } else {
      final t = (progress - 0.62) / 0.38;
      radius = largeRadius + ((baseRadius - largeRadius) * t);
      color = Color.lerp(
        AppColors.primary,
        AppColors.splashDot.withValues(alpha: 0.68),
        t,
      )!;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rows = (size.height / spacing).ceil() + 2;
    final columns = (size.width / spacing).ceil() + 2;

    for (var row = -1; row < rows; row++) {
      final y = row * spacing;

      for (var column = -1; column < columns; column++) {
        final x = column * spacing;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedDotGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
