import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/maker_registration_controller.dart';
import '../../data/maker_onboarding_repository.dart';
import '../../data/onboarding_prefill_repository.dart';
import '../../domain/maker_registration_options.dart';
import '../../domain/onboarding_validators.dart';
import '../widgets/ma_choice_chip.dart';
import '../widgets/ma_onboarding_scaffold.dart';
import '../widgets/ma_onboarding_text_field.dart';

class MakerRegistrationFlowScreen extends ConsumerStatefulWidget {
  const MakerRegistrationFlowScreen({
    super.key,
    required this.onExit,
    this.onCompleted,
    this.initialStep = 0,
    this.prefillFromAccount = false,
  }) : assert(initialStep >= 0 && initialStep < totalSteps);

  static const int totalSteps = 7;

  final VoidCallback onExit;
  final VoidCallback? onCompleted;
  final int initialStep;
  final bool prefillFromAccount;

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
  final Map<String, String> _fieldErrors = <String, String>{};
  bool _isSubmitting = false;
  bool _submissionCompleted = false;
  bool _prefilling = false;

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

    if (widget.prefillFromAccount) {
      _prefilling = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_prefillFromAccount());
      });
    }
  }

  static String _firstAvailable(Iterable<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static Set<String> _selectedNames(
    Object? data,
    List<String> available,
  ) {
    if (data is! List) return const <String>{};
    final labels = data.whereType<Map>().map(
      (item) => item['name']?.toString().trim().toLowerCase() ?? '',
    ).toSet();
    return available.where(
      (candidate) => labels.contains(candidate.toLowerCase()) ||
          (candidate == 'Graphic Designer' && labels.contains('graphic design')),
    ).toSet();
  }

  Future<void> _prefillFromAccount() async {
    try {
      final repository = ref.read(onboardingPrefillRepositoryProvider);
      final user = await repository.account();
      if (user == null || !mounted) return;

      // Only a currently active, incomplete Maker profile can be fetched
      // through the Maker-scoped endpoint. /me supplies both locations.
      var makerProfile = <String, dynamic>{};
      if (user.isMaker &&
          user.makerRegistered &&
          !user.makerOnboardingCompleted) {
        makerProfile = await repository.incompleteMakerProfile();
      }
      if (!mounted) return;

      final draft = ref.read(makerRegistrationProvider);
      final controller = ref.read(makerRegistrationProvider.notifier);

      final name = _firstAvailable(<String>[draft.name, user.name]);
      final location = _firstAvailable(<String>[
        draft.location,
        makerProfile['location_text']?.toString() ?? '',
        user.makerLocation,
        user.appreciatorLocation,
      ]);
      final email = _firstAvailable(<String>[draft.email, user.email]);

      if (draft.name.trim().isEmpty && name.isNotEmpty) {
        controller.setName(name);
        _nameController.text = name;
      }
      if (draft.location.trim().isEmpty && location.isNotEmpty) {
        controller.setLocation(location);
        _locationController.text = location;
      }
      if (draft.email.trim().isEmpty && email.isNotEmpty) {
        controller.setEmail(email);
        _emailController.text = email;
      }

      final bio = _firstAvailable(<String>[
        draft.aboutWork,
        makerProfile['bio']?.toString() ?? '',
        user.makerBio,
      ]);
      if (draft.aboutWork.trim().isEmpty && bio.isNotEmpty) {
        controller.setAboutWork(bio);
        _aboutController.text = bio;
      }

      final website = _firstAvailable(<String>[
        draft.website,
        makerProfile['website_url']?.toString() ?? '',
      ]);
      if (draft.website.trim().isEmpty && website.isNotEmpty) {
        controller.setWebsite(website);
        _websiteController.text = website;
      }

      if (draft.types.isEmpty) {
        final types = _selectedNames(
          makerProfile['types'],
          MakerRegistrationOptions.types,
        );
        if (types.isNotEmpty) controller.setTypes(types);
      }
      if (draft.styles.isEmpty) {
        final styles = _selectedNames(
          makerProfile['styles'],
          MakerRegistrationOptions.styles,
        );
        if (styles.isNotEmpty) controller.setStyles(styles);
      }
      final image = _firstAvailable(<String>[
        draft.existingImageUrl ?? '',
        makerProfile['profile_image_url']?.toString() ?? '',
        user.makerProfileImageUrl ?? '',
      ]);
      if (draft.existingImageUrl == null && image.isNotEmpty) {
        controller.setExistingImageUrl(image);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _validationMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _validationMessage =
              'We could not restore your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _prefilling = false);
    }
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
    final draft = ref.read(makerRegistrationProvider);
    final errors = <String, String>{};

    switch (_step) {
      case 0:
        _addError(errors, 'name', OnboardingValidators.makerName(draft.name));
        break;
      case 1:
        _addError(
          errors,
          'location',
          OnboardingValidators.location(draft.location),
        );
        break;
      case 2:
        _addError(
          errors,
          'about',
          OnboardingValidators.aboutWork(draft.aboutWork),
        );
        break;
      case 3:
        _addError(
          errors,
          'types',
          OnboardingValidators.makerTypes(draft.types),
        );
        _addError(
          errors,
          'styles',
          OnboardingValidators.makerStyles(draft.styles),
        );
        break;
      case 4:
        _addError(
          errors,
          'website',
          OnboardingValidators.website(draft.website),
        );
        break;
      case 5:
        _addError(errors, 'email', OnboardingValidators.email(draft.email));
        break;
      case 6:
        if (draft.existingImageUrl?.trim().isNotEmpty != true ||
            draft.imageBytes != null) {
          _addError(
            errors,
            'image',
            OnboardingValidators.salonImage(
              bytes: draft.imageBytes,
              fileName: draft.imageName,
            ),
          );
        }
        break;
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
      _validationMessage = null;
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
      'bio': (step: 2, field: 'about'),
      'type_ids': (step: 3, field: 'types'),
      'style_ids': (step: 3, field: 'styles'),
      'website_url': (step: 4, field: 'website'),
      'email': (step: 5, field: 'email'),
      'contact_email': (step: 5, field: 'email'),
      'image': (step: 6, field: 'image'),
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
      _validationMessage = null;
      _submissionCompleted = false;
    });

    return true;
  }

  void _next() {
    unawaited(_handleNext());
  }

  Future<void> _handleNext() async {
    if (_isSubmitting ||
        _prefilling ||
        _submissionCompleted ||
        !_validateCurrentStep()) {
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
      _fieldErrors.remove('image');
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
            errorText: _fieldErrors['name'],
            onChanged: (value) {
              ref.read(makerRegistrationProvider.notifier).setName(value);
              _clearFieldError('name');
            },
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
            errorText: _fieldErrors['location'],
            onChanged: (value) {
              ref.read(makerRegistrationProvider.notifier).setLocation(value);
              _clearFieldError('location');
            },
          ),
        );

      case 2:
        return MaOnboardingScaffold(
          heading: 'Tell us about your work',
          subtitle: 'A few sentences about your practice (optional)',
          currentStep: _step,
          totalSteps: MakerRegistrationFlowScreen.totalSteps,
          onNext: _next,
          onBack: _back,
          validationMessage: _validationMessage,
          child: MaOnboardingTextField(
            key: const Key('maker_about_field'),
            controller: _aboutController,
            hintText: "I’m an artist exploring……",
            minLines: 4,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            errorText: _fieldErrors['about'],
            onChanged: (value) {
              ref.read(makerRegistrationProvider.notifier).setAboutWork(value);
              _clearFieldError('about');
            },
          ),
        );

      case 3:
        return _TypeStyleStep(
          currentStep: _step,
          validationMessage: _validationMessage,
          typeError: _fieldErrors['types'],
          styleError: _fieldErrors['styles'],
          onSelectionChanged: _clearFieldError,
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
            errorText: _fieldErrors['website'],
            onChanged: (value) {
              ref.read(makerRegistrationProvider.notifier).setWebsite(value);
              _clearFieldError('website');
            },
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
            errorText: _fieldErrors['email'],
            onChanged: (value) {
              ref.read(makerRegistrationProvider.notifier).setEmail(value);
              _clearFieldError('email');
            },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SalonImagePicker(
                imageBytes: imageBytes,
                existingImageUrl: ref.watch(
                  makerRegistrationProvider.select(
                    (draft) => draft.existingImageUrl,
                  ),
                ),
                onTap: _isSubmitting ? () {} : _pickImage,
              ),
              if (_fieldErrors['image'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  _fieldErrors['image']!,
                  key: const Key('maker_salon_image_error'),
                  style: AppTextStyles.onboardingError,
                ),
              ],
            ],
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
    required this.typeError,
    required this.styleError,
    required this.onSelectionChanged,
    required this.onNext,
    required this.onBack,
  });

  final int currentStep;
  final String? validationMessage;
  final String? typeError;
  final String? styleError;
  final ValueChanged<String> onSelectionChanged;
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
      contentTopWidthFactor: 0.13,
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
                  onTap: () {
                    controller.toggleType(type);
                    onSelectionChanged('types');
                  },
                ),
            ],
          ),
          if (typeError != null) ...[
            const SizedBox(height: 8),
            Text(
              typeError!,
              key: const Key('maker_type_error'),
              style: AppTextStyles.onboardingError,
            ),
          ],
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
                  onTap: () {
                    controller.toggleStyle(style);
                    onSelectionChanged('styles');
                  },
                ),
            ],
          ),
          if (styleError != null) ...[
            const SizedBox(height: 8),
            Text(
              styleError!,
              key: const Key('maker_style_error'),
              style: AppTextStyles.onboardingError,
            ),
          ],
        ],
      ),
    );
  }
}

class _SalonImagePicker extends StatelessWidget {
  const _SalonImagePicker({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBytes = imageBytes != null && imageBytes!.isNotEmpty;
    final hasImage = hasBytes || (existingImageUrl?.trim().isNotEmpty ?? false);

    return Semantics(
      button: true,
      label: hasImage ? 'Change salon image' : 'Upload salon image',
      child: InkWell(
        key: const Key('maker_salon_image_picker'),
        onTap: onTap,
        overlayColor: AppButtonStyles.purpleInkOverlay,
        child: Container(
          width: 132,
          height: 132,
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
              : hasBytes
              ? Image.memory(
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
                )
              : Image.network(
                  existingImageUrl!,
                  key: const Key('maker_salon_image_preview'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                ),
        ),
      ),
    );
  }
}
