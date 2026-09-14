import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/maker_registration_controller.dart';
import '../../data/maker_onboarding_repository.dart';
import '../../domain/maker_registration_options.dart';
import '../widgets/ma_choice_chip.dart';
import '../widgets/ma_onboarding_scaffold.dart';
import '../widgets/ma_onboarding_text_field.dart';

class MakerRegistrationFlowScreen extends ConsumerStatefulWidget {
  const MakerRegistrationFlowScreen({
    super.key,
    required this.onExit,
    this.onCompleted,
    this.initialStep = 0,
  }) : assert(initialStep >= 0 && initialStep < totalSteps);

  static const int totalSteps = 7;

  final VoidCallback onExit;
  final VoidCallback? onCompleted;
  final int initialStep;

  @override
  ConsumerState<MakerRegistrationFlowScreen> createState() =>
      _MakerRegistrationFlowScreenState();
}

class _MakerRegistrationFlowScreenState
    extends ConsumerState<MakerRegistrationFlowScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _aboutController;
  late final TextEditingController _websiteController;
  late final TextEditingController _emailController;

  late int _step;
  String? _validationMessage;
  bool _isSubmitting = false;
  bool _submissionCompleted = false;

  @override
  void initState() {
    super.initState();

    _step = widget.initialStep;

    final draft = ref.read(makerRegistrationProvider);

    _nameController = TextEditingController(text: draft.name);
    _locationController = TextEditingController(text: draft.location);
    _aboutController = TextEditingController(text: draft.aboutWork);
    _websiteController = TextEditingController(text: draft.website);
    _emailController = TextEditingController(text: draft.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _websiteController.dispose();
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
    final draft = ref.read(makerRegistrationProvider);

    String? message;

    switch (_step) {
      case 0:
        if (draft.name.trim().isEmpty) {
          message = 'Please enter your name or studio name.';
        }
        break;
      case 1:
        if (draft.location.trim().isEmpty) {
          message = 'Please enter your city or ZIP code.';
        }
        break;
      case 2:
        if (draft.aboutWork.trim().isEmpty) {
          message = 'Please tell us a little about your work.';
        }
        break;
      case 3:
        if (draft.types.isEmpty || draft.styles.isEmpty) {
          message = 'Select at least one type and one style.';
        }
        break;
      case 4:
        message = null;
        break;
      case 5:
        final email = draft.email.trim();
        final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

        if (email.isEmpty || !emailPattern.hasMatch(email)) {
          message = 'Please enter a valid email address.';
        }
        break;
      case 6:
        if (draft.imageBytes == null || draft.imageBytes!.isEmpty) {
          message = 'Please upload your salon image.';
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

    if (_step != MakerRegistrationFlowScreen.totalSteps - 1) {
      _goToStep(_step + 1);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });

    try {
      final draft = ref.read(makerRegistrationProvider);
      await ref
          .read(makerOnboardingRepositoryProvider)
          .completeMakerProfile(draft);

      if (!mounted) {
        return;
      }

      setState(() {
        _submissionCompleted = true;
        _validationMessage = widget.onCompleted == null
            ? 'Profile saved successfully.'
            : null;
      });

      if (widget.onCompleted != null) {
        ref.read(makerRegistrationProvider.notifier).reset();
        widget.onCompleted!.call();
      }
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
            'We could not save your profile. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    if (!mounted) {
      return;
    }

    ref
        .read(makerRegistrationProvider.notifier)
        .setImage(
          bytes: bytes,
          name: file.name,
          path: file.path.isEmpty ? null : file.path,
        );

    setState(() {
      _validationMessage = null;
      _submissionCompleted = false;
    });
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
          heading: "What's your name or studio name?",
          subtitle: "This is how you'll appear to others",
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('maker_name_field'),
            controller: _nameController,
            hintText: 'Your name',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: ref.read(makerRegistrationProvider.notifier).setName,
          ),
        );

      case 1:
        return MaOnboardingScaffold(
          heading: 'Where are you based?',
          subtitle: 'Help others discover local artists',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('maker_location_field'),
            controller: _locationController,
            hintText: 'City/Zip Code',
            textInputAction: TextInputAction.next,
            onChanged: ref.read(makerRegistrationProvider.notifier).setLocation,
          ),
        );

      case 2:
        return MaOnboardingScaffold(
          heading: 'Tell us about your work',
          subtitle: 'A few sentences about your practice',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          centerContentWhenKeyboardOpen: true,
          child: MaOnboardingTextField(
            key: const Key('maker_about_field'),
            controller: _aboutController,
            hintText: "I’m an artist exploring……",
            minLines: 4,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: ref
                .read(makerRegistrationProvider.notifier)
                .setAboutWork,
          ),
        );

      case 3:
        return _TypeStyleStep(
          currentStep: _step,
          validationMessage: _validationMessage,
          onNext: _next,
          onBack: _back,
        );

      case 4:
        return MaOnboardingScaffold(
          heading: 'Your Website',
          subtitle: 'Share your personal or studio site (Optional)',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('maker_website_field'),
            controller: _websiteController,
            hintText: 'www.yoursite.com',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.url],
            onChanged: ref.read(makerRegistrationProvider.notifier).setWebsite,
          ),
        );

      case 5:
        return MaOnboardingScaffold(
          heading: 'Email Address',
          subtitle: 'For Notifications and updates',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('maker_email_field'),
            controller: _emailController,
            hintText: 'your@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: ref.read(makerRegistrationProvider.notifier).setEmail,
          ),
        );

      case 6:
        final imageBytes = ref.watch(
          makerRegistrationProvider.select((draft) => draft.imageBytes),
        );

        return MaOnboardingScaffold(
          heading: 'Upload your salon image',
          subtitle:
              'This will be the primary image representing you and your work. '
              'You can always change it later.',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          isBusy: _isSubmitting,
          child: _SalonImagePicker(
            imageBytes: imageBytes,
            onTap: _isSubmitting ? () {} : _pickImage,
          ),
        );

      default:
        throw StateError('Unsupported maker registration step: $_step');
    }
  }
}

class _TypeStyleStep extends ConsumerWidget {
  const _TypeStyleStep({
    required this.currentStep,
    required this.validationMessage,
    required this.onNext,
    required this.onBack,
  });

  final int currentStep;
  final String? validationMessage;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(makerRegistrationProvider);
    final controller = ref.read(makerRegistrationProvider.notifier);

    return MaOnboardingScaffold(
      heading: 'What kind of work do\nyou make?',
      subtitle: 'Select all that apply',
      currentStep: currentStep,
      totalSteps: MakerRegistrationFlowScreen.totalSteps,
      onNext: onNext,
      onBack: onBack,
      validationMessage: validationMessage,
      contentTopWidthFactor: 0.145,
      childGap: 12,
      contentBottom: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type',
            style: AppTextStyles.onboardingHelper.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            key: const Key('maker_type_options'),
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final type in MakerRegistrationOptions.types)
                MaChoiceChip(
                  key: Key('maker_type_$type'),
                  label: type,
                  selected: draft.types.contains(type),
                  onTap: () => controller.toggleType(type),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Style',
            style: AppTextStyles.onboardingHelper.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            key: const Key('maker_style_options'),
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final style in MakerRegistrationOptions.styles)
                MaChoiceChip(
                  key: Key('maker_style_$style'),
                  label: style,
                  selected: draft.styles.contains(style),
                  onTap: () => controller.toggleStyle(style),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalonImagePicker extends StatelessWidget {
  const _SalonImagePicker({required this.imageBytes, required this.onTap});

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null && imageBytes!.isNotEmpty;

    return Semantics(
      button: true,
      label: hasImage ? 'Change salon image' : 'Upload salon image',
      child: InkWell(
        key: const Key('maker_salon_image_picker'),
        onTap: onTap,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: hasImage ? AppColors.inputFill : Colors.transparent,
            border: Border.all(color: AppColors.primary50, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: !hasImage
              ? const Center(
                  child: Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 38,
                    weight: 300,
                  ),
                )
              : Image.memory(
                  imageBytes!,
                  key: const Key('maker_salon_image_preview'),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
