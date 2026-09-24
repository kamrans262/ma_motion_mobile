import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/domain/onboarding_validators.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_text_field.dart';
import '../widgets/ma_email_auth_layout.dart';
import '../../../onboarding/presentation/widgets/ma_role_selection_wandering_dots.dart';
import '../../data/email_otp_repository.dart';
import '../../data/maker_entry_repository.dart';
import '../../domain/maker_entry_destination.dart';
import 'ma_email_otp_screen.dart';

class MaEmailLoginScreen extends ConsumerStatefulWidget {
  const MaEmailLoginScreen({
    super.key,
    required this.onCreateAccount,
    required this.onAuthenticated,
  });

  final VoidCallback onCreateAccount;
  final ValueChanged<MakerEntryDestination> onAuthenticated;

  @override
  ConsumerState<MaEmailLoginScreen> createState() => _MaEmailLoginScreenState();
}

class _MaEmailLoginScreenState extends ConsumerState<MaEmailLoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  late final AnimationController _wanderingController;
  Timer? _startDelay;
  EmailOtpChallenge? _challenge;
  String? _emailError;
  String? _generalError;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _wanderingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _startDelay = Timer(const Duration(seconds: 1), () {
      if (mounted) _wanderingController.forward();
    });
  }

  @override
  void dispose() {
    _startDelay?.cancel();
    _wanderingController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSending) return;

    final email = _emailController.text.trim();
    final validation = OnboardingValidators.email(email);
    if (validation != null) {
      setState(() {
        _emailError = validation;
        _generalError = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _emailError = null;
      _generalError = null;
    });

    try {
      final challenge = await ref
          .read(emailOtpRepositoryProvider)
          .requestLogin(email);
      if (!mounted) return;
      setState(() => _challenge = challenge);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _generalError = error.fieldErrors['email']?.firstOrNull ?? error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _generalError =
              'We could not send the verification code. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _finishLogin() async {
    try {
      final destination = await ref
          .read(makerEntryRepositoryProvider)
          .restoreAppEntry();
      if (!mounted) return;
      widget.onAuthenticated(destination);
    } on ApiException catch (error) {
      if (mounted) setState(() => _generalError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _generalError = 'We could not open your account. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    if (challenge != null) {
      return MaEmailOtpScreen(
        challenge: challenge,
        onBack: () => setState(() => _challenge = null),
        onVerified: (_, result) {
          if (result.isAuthenticated) {
            unawaited(_finishLogin());
          }
        },
      );
    }

    return MaEmailAuthLayout(
      screenKey: const Key('email_login_screen'),
      background: MaRoleSelectionWanderingDots(
        progress: _wanderingController,
      ),
      heading: 'Your creative space awaits',
      headingKey: const Key('email_login_heading'),
      subtitle: 'Enter your email address to continue',
      primaryKey: const Key('email_login_button'),
      primaryLabel: _isSending ? 'Sending...' : 'Login',
      onPrimary: _isSending ? null : _login,
      secondaryKey: const Key('email_create_account_button'),
      secondaryLabel: 'Create Account',
      onSecondary: _isSending ? null : widget.onCreateAccount,
      belowSecondary: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'By continuing, you agree to our',
              key: Key('email_login_legal_intro'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            ),
            SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Terms & Conditions',
                    key: Key('email_login_terms_text'),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '·',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Privacy Policy',
                    key: Key('email_login_privacy_text'),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MaOnboardingTextField(
            key: const Key('email_login_field'),
            controller: _emailController,
            hintText: 'your@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null || _generalError != null) {
                setState(() {
                  _emailError = null;
                  _generalError = null;
                });
              }
            },
            onSubmitted: (_) => unawaited(_login()),
          ),
          if (_generalError != null) ...[
            const SizedBox(height: 10),
            Text(
              _generalError!,
              key: const Key('email_login_error'),
              style: AppTextStyles.onboardingError,
            ),
          ],
        ],
      ),
    );
  }
}
