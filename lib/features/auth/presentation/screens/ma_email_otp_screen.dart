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
      if (code.length != 6) {
        setState(() => _error = 'Please enter the 6-digit code.');
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _OtpLoadingDialog(),
      ),
    );

    try {
      final result = await ref
          .read(emailOtpRepositoryProvider)
          .verify(challenge: _challenge, code: code);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _OtpSuccessDialog(),
      );

      if (!mounted) return;
      widget.onVerified(_challenge, result);
    } on ApiException catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final codeError = error.fieldErrors['code'];
      setState(() {
        _error = codeError?.isNotEmpty == true ? codeError!.first : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _error = 'We could not verify the code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_isResending || _resendSeconds > 0) return;

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
      primaryKey: const Key('email_otp_verify_button'),
      primaryLabel: 'Verify OTP',
      onPrimary: _isVerifying ? null : _verify,
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
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.primary,
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
          const SizedBox(height: 12),
          TextButton(
            key: const Key('email_otp_resend_button'),
            onPressed: _isVerifying || _isResending || _resendSeconds > 0
                ? null
                : _resend,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _resendSeconds > 0
                  ? 'Resend OTP in ${_resendSeconds}s'
                  : _isResending
                  ? 'Sending...'
                  : 'Resend OTP',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpLoadingDialog extends StatelessWidget {
  const _OtpLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.splashBackground,
      shape: const RoundedRectangleBorder(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 18),
            Flexible(
              child: Text(
                'Verifying OTP...',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpSuccessDialog extends StatelessWidget {
  const _OtpSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.splashBackground,
      shape: const RoundedRectangleBorder(),
      title: const Text(
        'Email verified successfully.',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('email_otp_success_continue'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Continue',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
