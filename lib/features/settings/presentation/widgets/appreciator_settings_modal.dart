import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/experience_switch_repository.dart';
import '../../../auth/domain/maker_entry_destination.dart';
import '../../data/appreciator_settings_repository.dart';
import '../../domain/appreciator_settings_models.dart';
import 'ma_settings_dialogs.dart';

Future<MakerEntryDestination?> showAppreciatorSettingsModal(
  BuildContext context,
) {
  return showGeneralDialog<MakerEntryDestination>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close settings',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: const Center(child: AppreciatorSettingsModal()),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppreciatorSettingsModal extends ConsumerStatefulWidget {
  const AppreciatorSettingsModal({super.key});

  @override
  ConsumerState<AppreciatorSettingsModal> createState() =>
      _AppreciatorSettingsModalState();
}

class _AppreciatorSettingsModalState
    extends ConsumerState<AppreciatorSettingsModal> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();

  AppreciatorSettingsData? _data;
  String _initialLocation = '';
  int? _initialLocationId;

  bool _loading = true;
  bool _saving = false;
  bool _switching = false;
  String? _errorMessage;
  String? _successMessage;
  final Map<String, String> _fieldErrors = <String, String>{};

  bool get _busy => _saving || _switching;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final data = await ref.read(appreciatorSettingsRepositoryProvider).load();

      if (!mounted) return;

      _nameController.text = data.name;
      _locationController.text = data.locationText;
      _emailController.text = data.email;
      _initialLocation = data.locationText.trim();
      _initialLocationId = data.locationId;

      setState(() {
        _data = data;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'We could not load your Appreciator settings. Please try again.';
      });
    }
  }

  bool _validate() {
    _fieldErrors.clear();

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final email = _emailController.text.trim();
    final emailParts = email.split('@');
    final emailLooksValid =
        emailParts.length == 2 &&
        emailParts.first.isNotEmpty &&
        emailParts.last.contains('.') &&
        !email.contains(' ');

    if (name.isEmpty) {
      _fieldErrors['name'] = 'Please enter your name.';
    }
    if (location.isEmpty) {
      _fieldErrors['location_text'] = 'Please enter your location.';
    }
    if (email.isEmpty || !emailLooksValid) {
      _fieldErrors['email'] = 'Please enter a valid email address.';
    }

    if (_fieldErrors.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
      return false;
    }

    return true;
  }

  Future<AppreciatorSettingsData?> _saveProfile({
    required bool showSuccess,
  }) async {
    if (_busy || !_validate()) {
      return null;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _successMessage = null;
      _fieldErrors.clear();
    });

    final repository = ref.read(appreciatorSettingsRepositoryProvider);

    try {
      final locationText = _locationController.text.trim();
      final locationId = locationText == _initialLocation
          ? _initialLocationId
          : await repository.resolveLocationId(locationText);

      final saved = await repository.save(
        AppreciatorSettingsDraft(
          name: _nameController.text,
          email: _emailController.text,
          locationText: locationText,
          locationId: locationId,
        ),
      );

      if (!mounted) return null;

      _initialLocation = saved.locationText.trim();
      _initialLocationId = saved.locationId;

      setState(() {
        _data = saved;
        _successMessage = showSuccess ? 'Settings saved.' : null;
      });

      return saved;
    } on ApiException catch (error) {
      if (!mounted) return null;

      final fieldErrors = <String, String>{};
      for (final entry in error.fieldErrors.entries) {
        if (entry.value.isNotEmpty) {
          fieldErrors[entry.key] = entry.value.first;
        }
      }

      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(fieldErrors);
        _errorMessage = error.message;
      });
      return null;
    } catch (_) {
      if (!mounted) return null;
      setState(() {
        _errorMessage =
            'We could not save your Appreciator settings. Please try again.';
      });
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _saveAndClose() async {
    FocusScope.of(context).unfocus();

    final saved = await _saveProfile(showSuccess: true);
    if (saved == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    if (_busy) return;

    setState(() {
      _switching = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // The existing logout repository clears the local token even if the
      // logout request fails. Return to Login after local sign-out.
    }

    if (!mounted) return;
    Navigator.of(context).pop(MakerEntryDestination.join);
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final deleted = await showMaDeleteAccountDialog(context);
    if (!mounted || !deleted) return;
    Navigator.of(context).pop(MakerEntryDestination.join);
  }

  Future<void> _switchToMaker() async {
    FocusScope.of(context).unfocus();

    final saved = await _saveProfile(showSuccess: false);
    if (saved == null || !mounted) return;

    setState(() {
      _switching = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final destination = await ref
          .read(experienceSwitchRepositoryProvider)
          .switchToMaker();

      if (!mounted) return;
      Navigator.of(context).pop(destination);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _switching = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _switching = false;
        _errorMessage =
            'We could not switch to Maker right now. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            media.size.width < 360 ? 16 : 20,
            20,
            media.size.width < 360 ? 16 : 20,
            media.viewInsets.bottom + 20,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight.clamp(300.0, 600.0);

              return Center(
                child: Material(
                  key: const Key('appreciator_settings_card'),
                  color: AppColors.artworkBackground,
                  elevation: 18,
                  shadowColor: Colors.black,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                      maxHeight: maxHeight,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 300,
                            height: 280,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : _data == null
                        ? _LoadFailure(
                            message:
                                _errorMessage ??
                                'We could not load your Appreciator settings.',
                            onRetry: _load,
                          )
                        : _buildForm(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      key: const Key('appreciator_settings_scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Settings',
                key: Key('appreciator_settings_heading'),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              TextButton(
                key: const Key('appreciator_settings_logout'),
                onPressed: _busy ? null : _logout,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGray,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsField(
            fieldKey: const Key('appreciator_settings_name'),
            label: 'Name',
            controller: _nameController,
            errorText: _fieldErrors['name'],
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearFieldError('name'),
          ),
          const SizedBox(height: 13),
          _SettingsField(
            fieldKey: const Key('appreciator_settings_location'),
            label: 'Location',
            controller: _locationController,
            errorText: _fieldErrors['location_text'],
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearFieldError('location_text'),
          ),
          const SizedBox(height: 13),
          _SettingsField(
            fieldKey: const Key('appreciator_settings_email'),
            label: 'Email Address',
            controller: _emailController,
            errorText: _fieldErrors['email'],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _clearFieldError('email'),
          ),
          const SizedBox(height: 11),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('appreciator_settings_switch_to_maker'),
              onPressed: _busy ? null : _switchToMaker,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                overlayColor: Colors.transparent,
                foregroundColor: AppColors.darkGray,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 20),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _switching ? 'Switching…' : 'Switch to Maker',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.darkGray,
                  color: AppColors.darkGray,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Terms & Conditions',
              key: Key('appreciator_settings_terms_text'),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.darkGray,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.darkGray,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Privacy Policy',
              key: Key('appreciator_settings_privacy_text'),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: AppColors.darkGray,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.darkGray,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('appreciator_settings_delete_account'),
              onPressed: _busy ? null : _deleteAccount,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                overlayColor: Colors.transparent,
                foregroundColor: AppColors.darkGray,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 20),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Delete Your Account',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.darkGray,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationThickness: 1.5,
                  color: AppColors.darkGray,
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              key: const Key('appreciator_settings_error'),
              style: AppTextStyles.error.copyWith(fontSize: 14),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _successMessage!,
              key: const Key('appreciator_settings_success'),
              style: AppTextStyles.onboardingHelper.copyWith(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              key: const Key('appreciator_settings_save_close'),
              onPressed: _busy ? null : _saveAndClose,
              style: AppButtonStyles.filterAction(),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Save & Close',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field) &&
        _errorMessage == null &&
        _successMessage == null) {
      return;
    }

    setState(() {
      _fieldErrors.remove(field);
      _errorMessage = null;
      _successMessage = null;
    });
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.errorText,
    required this.textInputAction,
    required this.onChanged,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          enabled: true,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: AppColors.white,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            isDense: true,
            errorText: errorText,
            errorStyle: AppTextStyles.error.copyWith(fontSize: 14),
            filled: true,
            fillColor: AppColors.filterInputFill,
            contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary50),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.onboardingHelper,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('appreciator_settings_retry'),
              onPressed: onRetry,
              style: AppButtonStyles.outlineAction(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
