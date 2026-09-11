import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import '../widgets/ma_full_logo.dart';

/// One continuous MA Motion splash animation:
/// logo first, then animated welcome copy.
class MaSplashSequenceScreen extends StatefulWidget {
  const MaSplashSequenceScreen({
    super.key,
    this.onFinished,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 4400),
  });

  final VoidCallback? onFinished;
  final bool autoPlay;
  final Duration duration;

  @override
  State<MaSplashSequenceScreen> createState() => _MaSplashSequenceScreenState();
}

class _MaSplashSequenceScreenState extends State<MaSplashSequenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final Animation<double> _lineOneOpacity;
  late final Animation<double> _lineTwoOpacity;
  late final Animation<double> _lineThreeOpacity;

  late final Animation<Offset> _lineOneSlide;
  late final Animation<Offset> _lineTwoSlide;
  late final Animation<Offset> _lineThreeSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween<double>(1), weight: 68),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1,
              end: 0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 32,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.00, 0.45),
          ),
        );

    _lineOneOpacity = _fadeIn(0.40, 0.57);
    _lineTwoOpacity = _fadeIn(0.48, 0.65);
    _lineThreeOpacity = _fadeIn(0.56, 0.73);

    _lineOneSlide = _slideIn(0.40, 0.57);
    _lineTwoSlide = _slideIn(0.48, 0.65);
    _lineThreeSlide = _slideIn(0.56, 0.73);

    _controller.addStatusListener(_handleStatus);

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  Animation<double> _fadeIn(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<Offset> _slideIn(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ma_animated_splash'),
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MaDottedBackground(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: const _MaSplashLogo(),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: _WelcomeMessage(
                        lineOneOpacity: _lineOneOpacity.value,
                        lineTwoOpacity: _lineTwoOpacity.value,
                        lineThreeOpacity: _lineThreeOpacity.value,
                        lineOneSlide: _lineOneSlide.value,
                        lineTwoSlide: _lineTwoSlide.value,
                        lineThreeSlide: _lineThreeSlide.value,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MaSplashLogo extends StatelessWidget {
  const _MaSplashLogo();

  @override
  Widget build(BuildContext context) {
    return const MaFullLogo();
  }
}

class _WelcomeMessage extends StatelessWidget {
  const _WelcomeMessage({
    required this.lineOneOpacity,
    required this.lineTwoOpacity,
    required this.lineThreeOpacity,
    required this.lineOneSlide,
    required this.lineTwoSlide,
    required this.lineThreeSlide,
  });

  final double lineOneOpacity;
  final double lineTwoOpacity;
  final double lineThreeOpacity;

  final Offset lineOneSlide;
  final Offset lineTwoSlide;
  final Offset lineThreeSlide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fontSize = (width * 0.071).clamp(24.0, 56.0);

        final textStyle = TextStyle(
          color: AppColors.primary,
          fontFamily: 'Arial',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          height: 1.14,
          letterSpacing: -0.6,
        );

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.13),
            child: Semantics(
              label: 'Welcome to MA:A. Place where art and design live.',
              child: Column(
                key: const Key('ma_splash_welcome_text'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedTextLine(
                    key: const Key('ma_splash_line_1'),
                    text: 'Welcome to MA:A',
                    opacity: lineOneOpacity,
                    slide: lineOneSlide,
                    style: textStyle,
                  ),
                  _AnimatedTextLine(
                    key: const Key('ma_splash_line_2'),
                    text: 'Place where art &',
                    opacity: lineTwoOpacity,
                    slide: lineTwoSlide,
                    style: textStyle,
                  ),
                  _AnimatedTextLine(
                    key: const Key('ma_splash_line_3'),
                    text: 'design live.',
                    opacity: lineThreeOpacity,
                    slide: lineThreeSlide,
                    style: textStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedTextLine extends StatelessWidget {
  const _AnimatedTextLine({
    super.key,
    required this.text,
    required this.opacity,
    required this.slide,
    required this.style,
  });

  final String text;
  final double opacity;
  final Offset slide;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: slide,
      child: Opacity(
        opacity: opacity,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: style,
        ),
      ),
    );
  }
}
