import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../application/appreciator_registration_controller.dart';
import '../../data/appreciator_onboarding_repository.dart';
import '../widgets/ma_onboarding_scaffold.dart';
import '../widgets/ma_onboarding_text_field.dart';

class AppreciatorRegistrationFlowScreen extends ConsumerStatefulWidget {
  const AppreciatorRegistrationFlowScreen({
    super.key,
    required this.onExit,
    this.onCompleted,
    this.initialStep = 0,
  }) : assert(initialStep >= 0 && initialStep < totalSteps);

  static const int totalSteps = 3;

  final VoidCallback onExit;
  final VoidCallback? onCompleted;
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
  bool _isSubmitting = false;
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
    String? message;

    switch (_step) {
      case 0:
        if (draft.name.trim().isEmpty) {
          message = 'Please enter your name.';
        }
        break;
      case 1:
        if (draft.location.trim().isEmpty) {
          message = 'Please enter your city or ZIP code.';
        }
        break;
      case 2:
        final email = draft.email.trim();
        final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

        if (email.isEmpty || !emailPattern.hasMatch(email)) {
          message = 'Please enter a valid email address.';
        }
        break;
    }

    setState(() {
      _validationMessage = message;
    });

    return message == null;
  }

  void _next() {
    unawaited(_handleNext());
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

      setState(() {
        _validationMessage = error.message;
      });
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
            onChanged:
                ref.read(appreciatorRegistrationProvider.notifier).setName,
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
            onChanged:
                ref.read(appreciatorRegistrationProvider.notifier).setLocation,
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
          child: MaOnboardingTextField(
            key: const Key('appreciator_email_field'),
            controller: _emailController,
            hintText: 'your@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged:
                ref.read(appreciatorRegistrationProvider.notifier).setEmail,
          ),
        );

      default:
        throw StateError('Unsupported Appreciator registration step: $_step');
    }
  }
}
