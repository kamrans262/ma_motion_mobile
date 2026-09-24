import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import '../widgets/ma_email_auth_layout.dart';
import '../../data/email_otp_repository.dart';

class MaEmailOtpScreen extends ConsumerStatefulWidget {
  const MaEmailOtpScreen({
    super.key,
    required this.challenge,
    required this.onVerified,
    required this.onBack,
  });

  final EmailOtpChallenge challenge;
  final void Function(
    EmailOtpChallenge challenge,
    EmailOtpVerificationResult result,
  )
  onVerified;
  final VoidCallback onBack;

  @override
  ConsumerState<MaEmailOtpScreen> createState() => _MaEmailOtpScreenState();
}

class _MaEmailOtpScreenState extends ConsumerState<MaEmailOtpScreen> {
  final List<TextEditingController> _digitControllers =
      List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _digitFocus = List<FocusNode>.generate(
    6,
    (_) => FocusNode(),
  );
  final List<String> _digits = List<String>.filled(6, '');
  Timer? _resendTimer;
  late EmailOtpChallenge _challenge;
  late int _resendSeconds;
  String? _error;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _restartResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _digitFocus) {
      node.dispose();
    }
    super.dispose();
  }

  void _restartResendCountdown() {
    _resendTimer?.cancel();
    _resendSeconds = _challenge.resendAfterSeconds;
    if (_resendSeconds <= 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _onDigitChanged(int index, String raw) {
    if (_isVerifying) return;

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final previousDigit = _digits[index];
    if (digits.isEmpty) {
      _digits[index] = '';
      if (_digitControllers[index].text.isNotEmpty) {
        _digitControllers[index].clear();
      }
      if (_error != null) setState(() => _error = null);
      if (index > 0) _digitFocus[index - 1].requestFocus();
      return;
    }

    // Typing over a populated box replaces it; pasting a complete code
    // distributes all six digits even when another box has focus.
    final replacing = digits.length == 2 &&
        previousDigit.isNotEmpty &&
        digits.startsWith(previousDigit);
    final incoming = replacing ? digits.substring(1) : digits;
    final start = incoming.length == 6 ? 0 : index;

    for (var offset = 0; offset < incoming.length; offset++) {
      final target = start + offset;
      if (target >= 6) break;
      final digit = incoming[offset];
      _digits[target] = digit;
      _digitControllers[target].value = TextEditingValue(
        text: digit,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    if (_error != null) setState(() => _error = null);

    if (_digits.every((digit) => digit.isNotEmpty)) {
      unawaited(_verify());
    } else {
      final next = math.min(start + incoming.length, 5);
      _digitFocus[next].requestFocus();
    }
  }

  KeyEventResult _onDigitKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        index > 0 &&
        _digitControllers[index].text.isEmpty) {
      _digitFocus[index - 1].requestFocus();
      _digits[index - 1] = '';
      _digitControllers[index - 1].clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    final code = _digits.join();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    EmailOtpVerificationResult? result;
    String? failureMessage;
    var clearInvalidCode = false;

    try {
      result = await ref
          .read(emailOtpRepositoryProvider)
          .verify(challenge: _challenge, code: code);
    } on ApiException catch (error) {
      final codeError = error.fieldErrors['code'];
      clearInvalidCode = codeError?.isNotEmpty == true;
      failureMessage = clearInvalidCode ? codeError!.first : error.message;
    } catch (_) {
      failureMessage = 'We could not verify the code. Please try again.';
    }

    if (!mounted) return;

    if (failureMessage != null) {
      if (clearInvalidCode) {
        for (var index = 0; index < 6; index++) {
          _digits[index] = '';
          _digitControllers[index].clear();
        }
        _digitFocus.first.requestFocus();
      }
      setState(() => _error = failureMessage);
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: _OtpResultDialog(
          success: result != null,
          errorMessage: failureMessage,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      widget.onVerified(_challenge, result);
    }
    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _resend() async {
    if (_isVerifying || _isResending || _resendSeconds > 0) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      final challenge = await ref
          .read(emailOtpRepositoryProvider)
          .resend(_challenge);
      if (!mounted) return;

      setState(() {
        _challenge = challenge;
        for (var index = 0; index < 6; index++) {
          _digits[index] = '';
          _digitControllers[index].clear();
        }
        _digitFocus.first.requestFocus();
      });
      _restartResendCountdown();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'We could not resend the code. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaEmailAuthLayout(
      screenKey: const Key('email_otp_screen'),
      background: const MaDottedBackground(),
      heading: 'Verify your email',
      subtitle: 'Enter the 6-digit code sent to ${_challenge.email}',
      primaryKey: const Key('email_otp_resend_button'),
      primaryLabel: _isResending
          ? 'Sending...'
          : _resendSeconds > 0
          ? 'Resend OTP (${_resendSeconds}s)'
          : 'Resend OTP',
      onPrimary: _isVerifying || _isResending || _resendSeconds > 0
          ? null
          : _resend,
      secondaryKey: const Key('email_otp_back_button'),
      secondaryLabel: 'Back',
      onSecondary: _isVerifying ? null : widget.onBack,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            key: const Key('email_otp_six_digit_row'),
            children: [
              for (var index = 0; index < 6; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: Focus(
                    onKeyEvent: (_, event) => _onDigitKey(index, event),
                    child: TextField(
                      key: index == 0
                          ? const Key('email_otp_code_field')
                          : Key('email_otp_code_field_$index'),
                      controller: _digitControllers[index],
                      focusNode: _digitFocus[index],
                      enabled: !_isVerifying,
                      keyboardType: TextInputType.number,
                      textInputAction: index == 5
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: index == 0
                          ? const [AutofillHints.oneTimeCode]
                          : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onDigitChanged(index, value),
                      onSubmitted: (_) {
                        if (index == 5) unawaited(_verify());
                      },
                      textAlign: TextAlign.center,
                      style: AppTextStyles.field,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.primary50,
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.primary50,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('onboarding_field_error'),
              style: AppTextStyles.onboardingError,
            ),
          ],

        ],
      ),
    );
  }
}

class _OtpResultDialog extends StatefulWidget {
  const _OtpResultDialog({required this.success, this.errorMessage});

  final bool success;
  final String? errorMessage;

  @override
  State<_OtpResultDialog> createState() => _OtpResultDialogState();
}

class _OtpResultDialogState extends State<_OtpResultDialog> {
  Timer? _textTimer;
  Timer? _dismissTimer;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _textTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showText = true);
    });
    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.primary : AppColors.error;

    return AlertDialog(
      key: const Key('email_otp_result_dialog'),
      backgroundColor: AppColors.splashBackground,
      shape: const RoundedRectangleBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, progress, child) => CustomPaint(
              size: const Size(68, 68),
              painter: _OtpResultPainter(progress, color, widget.success),
            ),
          ),
          if (_showText) ...[
            const SizedBox(height: 16),
            Text(
              widget.success ? 'Email Verified.' : 'Verification Failed.',
              key: const Key('email_otp_result_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (!widget.success && widget.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorMessage!,
                key: const Key('email_otp_failure_reason'),
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingHelper,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OtpResultPainter extends CustomPainter {
  const _OtpResultPainter(this.progress, this.color, this.success);

  final double progress;
  final Color color;
  final bool success;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final circleProgress = (progress / 0.6).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 29),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      paint,
    );

    final markProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    if (markProgress <= 0) return;

    if (success) {
      final check = Path()
        ..moveTo(18, 35)
        ..lineTo(29, 45)
        ..lineTo(50, 23);
      final metric = check.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * markProgress),
        paint,
      );
    } else {
      final first = Path()
        ..moveTo(24, 24)
        ..lineTo(44, 44);
      final second = Path()
        ..moveTo(44, 24)
        ..lineTo(24, 44);
      final firstMetric = first.computeMetrics().first;
      final secondMetric = second.computeMetrics().first;
      canvas.drawPath(
        firstMetric.extractPath(0, firstMetric.length * markProgress),
        paint,
      );
      canvas.drawPath(
        secondMetric.extractPath(0, secondMetric.length * markProgress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OtpResultPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.success != success;
}
