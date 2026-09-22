import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_button.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_text_field.dart';
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
  final TextEditingController _codeController = TextEditingController();
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
    _codeController.dispose();
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

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (_isVerifying || code.length != 6) {
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
        _codeController.clear();
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
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const Key('email_otp_screen'),
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      72,
                      20,
                      keyboardBottom + 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 104,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify your email',
                            style: AppTextStyles.onboardingHeading.copyWith(
                              fontSize: 32,
                              letterSpacing: -0.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter the 6-digit code sent to ${_challenge.email}',
                            style: AppTextStyles.onboardingHelper,
                          ),
                          const SizedBox(height: 20),
                          MaOnboardingTextField(
                            key: const Key('email_otp_code_field'),
                            controller: _codeController,
                            hintText: '000000',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            errorText: _error,
                            onChanged: (_) {
                              if (_error != null) {
                                setState(() => _error = null);
                              }
                            },
                            onSubmitted: (_) => unawaited(_verify()),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            key: const Key('email_otp_resend_button'),
                            onPressed:
                                _isResending || _resendSeconds > 0
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
                          const SizedBox(height: 30),
                          MaOnboardingButton(
                            key: const Key('email_otp_verify_button'),
                            label: 'Verify OTP',
                            onPressed: _isVerifying ? null : _verify,
                            filled: false,
                            height: 53,
                          ),
                          const SizedBox(height: 13),
                          MaOnboardingButton(
                            key: const Key('email_otp_back_button'),
                            label: 'Back',
                            onPressed: _isVerifying ? null : widget.onBack,
                            filled: false,
                            subdued: true,
                            height: 53,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
