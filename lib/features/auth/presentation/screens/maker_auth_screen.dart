import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import '../../application/maker_auth_controller.dart';
import '../../domain/maker_entry_destination.dart';

class MakerAuthScreen extends ConsumerStatefulWidget {
  const MakerAuthScreen({
    super.key,
    required this.onBack,
    required this.onAuthenticated,
  });

  final VoidCallback onBack;
  final ValueChanged<MakerEntryDestination> onAuthenticated;

  @override
  ConsumerState<MakerAuthScreen> createState() => _MakerAuthScreenState();
}

class _MakerAuthScreenState extends ConsumerState<MakerAuthScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = ref.read(makerAuthControllerProvider);
    final controller = ref.read(makerAuthControllerProvider.notifier);

    controller.clearMessages();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isValidEmail(email)) {
      _showLocalError('Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      _showLocalError('Password must be at least 8 characters.');
      return;
    }

    MakerEntryDestination? destination;

    if (state.mode == MakerAuthMode.createAccount) {
      final name = _nameController.text.trim();
      final confirmation = _confirmController.text;

      if (name.isEmpty) {
        _showLocalError('Please enter your name.');
        return;
      }

      if (password != confirmation) {
        _showLocalError('Password confirmation does not match.');
        return;
      }

      destination = await controller.createAccount(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: confirmation,
      );
    } else {
      destination = await controller.signIn(email: email, password: password);
    }

    if (!mounted || destination == null) {
      return;
    }

    widget.onAuthenticated(destination);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _showLocalError(
        'Enter your email address first, then tap Forgot password.',
      );
      return;
    }

    await ref.read(makerAuthControllerProvider.notifier).forgotPassword(email);
  }

  void _showLocalError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.inputFill),
      );
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(makerAuthControllerProvider);
    final isCreate = state.mode == MakerAuthMode.createAccount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const Key('maker_auth_screen'),
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth < 360 ? 20.0 : 32.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      18,
                      horizontal,
                      32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            key: const Key('maker_auth_back_button'),
                            onPressed: state.isBusy ? null : widget.onBack,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            color: AppColors.primary,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            isCreate
                                ? 'Create your Maker account'
                                : 'Welcome back, Maker',
                            style: AppTextStyles.onboardingHeading,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isCreate
                                ? 'Create your secure account before completing your Maker profile.'
                                : 'Sign in to continue to your Maker profile and artwork.',
                            style: AppTextStyles.onboardingHelper,
                          ),
                          const SizedBox(height: 28),
                          _ModeSwitcher(
                            mode: state.mode,
                            enabled: !state.isBusy,
                            onChanged: (mode) {
                              ref
                                  .read(makerAuthControllerProvider.notifier)
                                  .setMode(mode);
                            },
                          ),
                          const SizedBox(height: 24),
                          if (isCreate) ...[
                            _AuthField(
                              key: const Key('maker_auth_name'),
                              controller: _nameController,
                              hintText: 'Name',
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _AuthField(
                            key: const Key('maker_auth_email'),
                            controller: _emailController,
                            hintText: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _AuthField(
                            key: const Key('maker_auth_password'),
                            controller: _passwordController,
                            hintText: 'Password',
                            obscureText: true,
                            autofillHints: isCreate
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            textInputAction: isCreate
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onSubmitted: isCreate ? null : (_) => _submit(),
                          ),
                          if (isCreate) ...[
                            const SizedBox(height: 14),
                            _AuthField(
                              key: const Key(
                                'maker_auth_password_confirmation',
                              ),
                              controller: _confirmController,
                              hintText: 'Confirm password',
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                          if (!isCreate) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                key: const Key('maker_auth_forgot_password'),
                                onPressed: state.isBusy
                                    ? null
                                    : _forgotPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.onboardingHelper
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage!,
                              key: const Key('maker_auth_error'),
                              style: AppTextStyles.error,
                            ),
                          ],
                          if (state.infoMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.infoMessage!,
                              key: const Key('maker_auth_info'),
                              style: AppTextStyles.onboardingHelper.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              key: const Key('maker_auth_submit_button'),
                              onPressed: state.isBusy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.black,
                                disabledBackgroundColor: AppColors.primary
                                    .withValues(alpha: 0.45),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: state.isBusy
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.black,
                                      ),
                                    )
                                  : Text(
                                      isCreate ? 'Create account' : 'Sign in',
                                      style: AppTextStyles.buttonDark,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Passwords must be at least 8 characters and include upper/lowercase letters and a number.',
                            style: AppTextStyles.onboardingHelper.copyWith(
                              fontSize: 12,
                            ),
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

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final MakerAuthMode mode;
  final bool enabled;
  final ValueChanged<MakerAuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            key: const Key('maker_auth_sign_in_mode'),
            label: 'Sign in',
            selected: mode == MakerAuthMode.signIn,
            enabled: enabled,
            onTap: () => onChanged(MakerAuthMode.signIn),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeButton(
            key: const Key('maker_auth_create_mode'),
            label: 'Create account',
            selected: mode == MakerAuthMode.createAccount,
            enabled: enabled,
            onTap: () => onChanged(MakerAuthMode.createAccount),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: selected
          ? FilledButton(
              onPressed: enabled ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(label, style: AppTextStyles.buttonDark),
            )
          : OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(label, style: AppTextStyles.buttonPurple),
            ),
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      obscureText: _obscured,
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      onSubmitted: widget.onSubmitted,
      style: AppTextStyles.field,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.fieldHint,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary50),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscured = !_obscured;
                  });
                },
                color: AppColors.mutedText,
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
