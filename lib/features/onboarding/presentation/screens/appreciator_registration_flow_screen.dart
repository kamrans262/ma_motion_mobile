import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/experience_switch_repository.dart';
import '../../../auth/domain/maker_entry_destination.dart';
import '../../application/appreciator_registration_controller.dart';
import '../../data/appreciator_onboarding_repository.dart';
import '../../domain/onboarding_validators.dart';
import '../widgets/ma_onboarding_scaffold.dart';
import '../widgets/ma_onboarding_text_field.dart';

class AppreciatorRegistrationFlowScreen extends ConsumerStatefulWidget {
  const AppreciatorRegistrationFlowScreen({
    super.key,
    required this.onExit,
    this.onCompleted,
    this.onSwitchToMaker,
    this.initialStep = 0,
  }) : assert(initialStep >= 0 && initialStep < totalSteps);

  static const int totalSteps = 3;

  final VoidCallback onExit;
  final VoidCallback? onCompleted;
  final ValueChanged<MakerEntryDestination>? onSwitchToMaker;
  final int initialStep;

  @override
  ConsumerState<AppreciatorRegistrationFlowScreen> createState() =>
      _AppreciatorRegistrationFlowScreenState();
}

class _AppreciatorRegistrationFlowScreenState
    extends ConsumerState<AppreciatorRegistrationFlowScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;

  late int _step;
  String? _validationMessage;
  final Map<String, String> _fieldErrors = <String, String>{};
  bool _isSubmitting = false;
  bool _isSwitchingExperience = false;
  bool _submissionCompleted = false;

  @override
  void initState() {
    super.initState();

    _step = widget.initialStep;
    final draft = ref.read(appreciatorRegistrationProvider);

    _nameController = TextEditingController(text: draft.name);
    _locationController = TextEditingController(text: draft.location);
    _emailController = TextEditingController(text: draft.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();

    setState(() {
      _step = step;
      _validationMessage = null;
      _fieldErrors.clear();
      _submissionCompleted = false;
    });
  }

  void _back() {
    if (_isSubmitting) {
      return;
    }

    if (_step == 0) {
      widget.onExit();
      return;
    }

    _goToStep(_step - 1);
  }

  bool _validateCurrentStep() {
    final draft = ref.read(appreciatorRegistrationProvider);
    final errors = <String, String>{};

    switch (_step) {
      case 0:
        _addError(
          errors,
          'name',
          OnboardingValidators.appreciatorName(draft.name),
        );
        break;
      case 1:
        _addError(
          errors,
          'location',
          OnboardingValidators.location(draft.location),
        );
        break;
      case 2:
        _addError(errors, 'email', OnboardingValidators.email(draft.email));
        break;
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
      _validationMessage = errors.isEmpty
          ? null
          : 'Please check the highlighted information.';
    });

    return errors.isEmpty;
  }

  static void _addError(
    Map<String, String> errors,
    String field,
    String? message,
  ) {
    if (message != null) {
      errors[field] = message;
    }
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field) && _validationMessage == null) {
      return;
    }

    setState(() {
      _fieldErrors.remove(field);
      if (_fieldErrors.isEmpty) {
        _validationMessage = null;
      }
      _submissionCompleted = false;
    });
  }

  bool _applyApiValidation(ApiException error) {
    if (error.fieldErrors.isEmpty) {
      return false;
    }

    const fieldMap = <String, ({int step, String field})>{
      'name': (step: 0, field: 'name'),
      'location_text': (step: 1, field: 'location'),
      'location_id': (step: 1, field: 'location'),
      'email': (step: 2, field: 'email'),
    };

    final mapped = <String, String>{};
    int? targetStep;

    for (final entry in error.fieldErrors.entries) {
      final mapping = fieldMap[entry.key];
      if (mapping == null || entry.value.isEmpty) {
        continue;
      }

      mapped[mapping.field] = entry.value.first;
      targetStep ??= mapping.step;
    }

    if (mapped.isEmpty || targetStep == null) {
      return false;
    }

    setState(() {
      _step = targetStep!;
      _fieldErrors
        ..clear()
        ..addAll(mapped);
      _validationMessage = 'Please check the highlighted information.';
      _submissionCompleted = false;
    });

    return true;
  }

  void _next() {
    unawaited(_handleNext());
  }

  Future<void> _switchToMaker() async {
    if (_isSubmitting || _isSwitchingExperience) {
      return;
    }

    setState(() {
      _isSwitchingExperience = true;
      _validationMessage = null;
    });

    try {
      final destination = await ref
          .read(experienceSwitchRepositoryProvider)
          .switchToMaker();

      if (!mounted) {
        return;
      }

      widget.onSwitchToMaker?.call(destination);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _validationMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _validationMessage =
            'We could not switch experiences right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingExperience = false;
        });
      }
    }
  }

  Future<void> _handleNext() async {
    if (_isSubmitting || _submissionCompleted || !_validateCurrentStep()) {
      return;
    }

    if (_step != AppreciatorRegistrationFlowScreen.totalSteps - 1) {
      _goToStep(_step + 1);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });

    try {
      final draft = ref.read(appreciatorRegistrationProvider);

      await ref
          .read(appreciatorOnboardingRepositoryProvider)
          .completeAppreciatorOnboarding(draft);

      if (!mounted) {
        return;
      }

      setState(() {
        _submissionCompleted = true;
        _validationMessage = null;
      });

      ref.read(appreciatorRegistrationProvider.notifier).reset();
      widget.onCompleted?.call();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (!_applyApiValidation(error)) {
        setState(() {
          _validationMessage = error.message;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _validationMessage =
            'We could not finish your Appreciator profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey<int>(_step),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return MaOnboardingScaffold(
          heading: "What's your name?",
          subtitle: "This is how you'll appear to others",
          currentStep: _step,
          totalSteps: AppreciatorRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('appreciator_name_field'),
            controller: _nameController,
            hintText: 'Your name',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: _fieldErrors['name'],
            onChanged: (value) {
              ref.read(appreciatorRegistrationProvider.notifier).setName(value);
              _clearFieldError('name');
            },
          ),
        );

      case 1:
        return MaOnboardingScaffold(
          heading: 'Where are you based?',
          subtitle: 'Help others discover local artists',
          currentStep: _step,
          totalSteps: AppreciatorRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('appreciator_location_field'),
            controller: _locationController,
            hintText: 'City/Zip Code',
            textInputAction: TextInputAction.next,
            errorText: _fieldErrors['location'],
            onChanged: (value) {
              ref
                  .read(appreciatorRegistrationProvider.notifier)
                  .setLocation(value);
              _clearFieldError('location');
            },
          ),
        );

      case 2:
        return MaOnboardingScaffold(
          heading: 'Email Address',
          subtitle: 'For Notifications and updates',
          currentStep: _step,
          totalSteps: AppreciatorRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          isBusy: _isSubmitting,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MaOnboardingTextField(
                key: const Key('appreciator_email_field'),
                controller: _emailController,
                hintText: 'your@gmail.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                errorText: _fieldErrors['email'],
                onChanged: (value) {
                  ref
                      .read(appreciatorRegistrationProvider.notifier)
                      .setEmail(value);
                  _clearFieldError('email');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('appreciator_switch_maker'),
                onPressed: _isSubmitting || _isSwitchingExperience
                    ? null
                    : _switchToMaker,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGray,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: const Text(
                  'Switch to Maker',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkGray,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.darkGray,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        throw StateError('Unsupported Appreciator registration step: $_step');
    }
  }
}
