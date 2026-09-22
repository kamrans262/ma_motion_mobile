import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/domain/onboarding_validators.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_button.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_text_field.dart';
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
      if (mounted) setState(() => _generalError = error.message);
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
        key: const Key('email_login_screen'),
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MaRoleSelectionWanderingDots(progress: _wanderingController),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                            'Login',
                            key: const Key('email_login_heading'),
                            style: AppTextStyles.onboardingHeading.copyWith(
                              fontSize: 32,
                              letterSpacing: -0.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your email address to continue',
                            style: AppTextStyles.onboardingHelper,
                          ),
                          const SizedBox(height: 20),
                          MaOnboardingTextField(
                            key: const Key('email_login_field'),
                            controller: _emailController,
                            hintText: 'your@gmail.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            errorText: _emailError,
                            onChanged: (_) {
                              if (_emailError != null ||
                                  _generalError != null) {
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
                          const SizedBox(height: 30),
                          MaOnboardingButton(
                            key: const Key('email_login_button'),
                            label: _isSending ? 'Sending...' : 'Login',
                            onPressed: _isSending ? null : _login,
                            filled: false,
                            height: 53,
                          ),
                          const SizedBox(height: 13),
                          MaOnboardingButton(
                            key: const Key('email_create_account_button'),
                            label: 'Create Account',
                            onPressed:
                                _isSending ? null : widget.onCreateAccount,
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
