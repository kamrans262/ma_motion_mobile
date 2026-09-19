import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/experience_switch_repository.dart';
import '../../../auth/domain/maker_entry_destination.dart';
import '../../../onboarding/presentation/widgets/ma_choice_chip.dart';
import '../../data/maker_info_settings_repository.dart';
import '../../domain/maker_info_settings_models.dart';

class MakerInfoSettingsScreen extends ConsumerStatefulWidget {
  const MakerInfoSettingsScreen({
    super.key,
    required this.onClose,
    required this.onSwitchedToAppreciator,
  });

  final VoidCallback onClose;
  final ValueChanged<MakerEntryDestination> onSwitchedToAppreciator;

  @override
  ConsumerState<MakerInfoSettingsScreen> createState() =>
      _MakerInfoSettingsScreenState();
}

class _MakerInfoSettingsScreenState
    extends ConsumerState<MakerInfoSettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _statementController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();

  final Map<int, TextEditingController> _captionControllers =
      <int, TextEditingController>{
        1: TextEditingController(),
        2: TextEditingController(),
        3: TextEditingController(),
        4: TextEditingController(),
      };
  final Map<int, TextEditingController> _artworkTitleControllers =
      <int, TextEditingController>{
        2: TextEditingController(),
        3: TextEditingController(),
        4: TextEditingController(),
      };

  MakerInfoSettingsData? _data;
  final Set<int> _selectedTypes = <int>{};
  final Set<int> _selectedStyles = <int>{};
  final Map<int, PendingCarouselMedia> _pendingMedia =
      <int, PendingCarouselMedia>{};
  final Set<int> _deletedSlots = <int>{};

  String _initialLocationText = '';
  int? _managedLocationId;

  bool _showWebsite = true;
  bool _showEmail = false;
  bool _showShows = true;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _statementController.dispose();
    _websiteController.dispose();
    _emailController.dispose();

    for (final controller in _captionControllers.values) {
      controller.dispose();
    }
    for (final controller in _artworkTitleControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref.read(makerInfoSettingsRepositoryProvider).load();

      if (!mounted) return;

      _nameController.text = data.name;
      _locationController.text = data.locationText;
      _initialLocationText = data.locationText.trim();
      _managedLocationId = data.managedLocationId;
      _statementController.text = data.bio;
      _websiteController.text = data.website;
      _emailController.text = data.email;

      _selectedTypes
        ..clear()
        ..addAll(data.selectedTypeIds);
      _selectedStyles
        ..clear()
        ..addAll(data.selectedStyleIds);

      _showWebsite = data.showWebsite;
      _showEmail = data.showEmail;
      _showShows = data.showShows;

      final salon = _existingItem(data, 1);
      _captionControllers[1]!.text = salon?.caption ?? '';

      for (var slot = 2; slot <= 4; slot++) {
        final artwork = _existingArtworkSlot(data, slot)?.artwork;
        _artworkTitleControllers[slot]!.text = artwork?.title ?? '';
        _captionControllers[slot]!.text = artwork?.description ?? '';
      }

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
            'We could not load your Maker settings. Please try again.';
      });
    }
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;

    for (var slot = 2; slot <= 4; slot++) {
      final existing = _existingArtworkSlot(_data, slot)?.artwork;
      final pending = _pendingMedia[slot];

      if ((existing != null || pending != null) &&
          !_deletedSlots.contains(slot) &&
          _artworkTitleControllers[slot]!.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a title for Content $slot artwork.';
        });
        return;
      }
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final repository = ref.read(makerInfoSettingsRepositoryProvider);
    final touchedArtworkSlots = <int>{};
    int? activeArtworkSlot;

    try {
      for (var slot = 2; slot <= 4; slot++) {
        final existing = _existingArtworkSlot(_data, slot)?.artwork;
        final pending = _pendingMedia[slot];
        final title = _artworkTitleControllers[slot]!.text.trim();
        final description = _captionControllers[slot]!.text.trim();
        final metadataChanged =
            existing != null &&
            (title != existing.title || description != existing.description);
        final shouldDelete = _deletedSlots.contains(slot);

        if (!shouldDelete && pending == null && !metadataChanged) {
          continue;
        }

        activeArtworkSlot = slot;
        touchedArtworkSlots.add(slot);

        if (shouldDelete) {
          await repository.deleteArtworkSlot(slot);
          continue;
        }

        final typeId =
            existing?.typeId ??
            (_selectedTypes.isEmpty ? null : _selectedTypes.first);
        final styleId =
            existing?.styleId ??
            (_selectedStyles.isEmpty ? null : _selectedStyles.first);
        final currentLocationId =
            _locationController.text.trim() == _initialLocationText
            ? _managedLocationId
            : null;

        await repository.saveArtworkSlot(
          slot: slot,
          existingArtwork: existing,
          title: title,
          description: description,
          typeId: typeId,
          styleId: styleId,
          locationId: existing?.locationId ?? currentLocationId,
          locationText: existing?.locationText.isNotEmpty == true
              ? existing!.locationText
              : _locationController.text.trim(),
          bytes: pending?.bytes,
          fileName: pending?.name,
        );
      }

      activeArtworkSlot = null;

      if (touchedArtworkSlots.isNotEmpty) {
        final confirmed = await repository.load();

        for (final slot in touchedArtworkSlots) {
          final saved = _existingArtworkSlot(confirmed, slot);

          if (_deletedSlots.contains(slot)) {
            if (saved != null) {
              throw ApiException(
                message: 'Content $slot removal could not be confirmed.',
                code: 'maker_info_slot_delete_unconfirmed',
              );
            }
            continue;
          }

          if (saved == null || saved.artwork.primaryImageUrl == null) {
            throw ApiException(
              message: 'Content $slot save could not be confirmed.',
              code: 'maker_info_slot_save_unconfirmed',
            );
          }
        }

        if (!mounted) return;

        setState(() {
          _data = confirmed;
          for (final slot in touchedArtworkSlots) {
            _pendingMedia.remove(slot);
            _deletedSlots.remove(slot);

            final artwork = _existingArtworkSlot(confirmed, slot)?.artwork;
            _artworkTitleControllers[slot]!.text = artwork?.title ?? '';
            _captionControllers[slot]!.text = artwork?.description ?? '';
          }
        });
      }

      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Content was saved, but please enter your Maker name before closing.';
        });
        return;
      }

      if (_selectedTypes.isEmpty || _selectedStyles.isEmpty) {
        setState(() {
          _errorMessage = 'Content was saved, but select at least one Type and one Style before closing.';
        });
        return;
      }

      await repository.saveProfile(
        MakerInfoSettingsDraft(
          name: _nameController.text,
          bio: _statementController.text,
          locationText: _locationController.text,
          website: _websiteController.text,
          email: _emailController.text,
          locationId: _locationController.text.trim() == _initialLocationText
              ? _managedLocationId
              : null,
          showWebsite: _showWebsite,
          showEmail: _showEmail,
          showShows: _showShows,
          typeIds: Set<int>.from(_selectedTypes),
          styleIds: Set<int>.from(_selectedStyles),
        ),
      );

      if (_deletedSlots.contains(1)) {
        await repository.deleteCarouselSlot(1);
      } else {
        final pending = _pendingMedia[1];
        final existing = _existingItem(_data, 1);
        final caption = _captionControllers[1]!.text.trim();
        final captionChanged = caption != (existing?.caption ?? '');

        if (pending != null || (existing != null && captionChanged)) {
          await repository.saveCarouselSlot(
            slot: 1,
            caption: caption,
            bytes: pending?.bytes,
            fileName: pending?.name,
          );
        }
      }

      if (!mounted) return;
      widget.onClose();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = activeArtworkSlot == null
            ? error.message
            : 'Content $activeArtworkSlot: ${error.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = activeArtworkSlot == null
            ? 'We could not save your Maker settings. Please try again.'
            : 'We could not save Content $activeArtworkSlot. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _chooseMedia(int slot) async {
    if (_saving) return;

    _MediaChoice? choice;

    if (slot == 1) {
      choice = await showModalBottomSheet<_MediaChoice>(
        context: context,
        backgroundColor: AppColors.inputFill,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Choose image',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(_MediaChoice.image),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.videocam_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Choose video (15 seconds max)',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(_MediaChoice.video),
                ),
              ],
            ),
          );
        },
      );
    } else {
      choice = _MediaChoice.image;
    }

    if (choice == null) return;

    XFile? file;

    if (choice == _MediaChoice.image) {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
        maxHeight: 1800,
      );
    } else {
      file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );
    }

    if (file == null) return;

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      _deletedSlots.remove(slot);
      _pendingMedia[slot] = PendingCarouselMedia(
        slot: slot,
        bytes: bytes,
        name: file!.name,
        kind: choice == _MediaChoice.video ? 'video' : 'image',
        caption: _captionControllers[slot]!.text,
      );

      if (slot >= 2 && _artworkTitleControllers[slot]!.text.trim().isEmpty) {
        final baseName = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
        _artworkTitleControllers[slot]!.text = baseName
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .trim();
      }
    });
  }

  void _removeSlot(int slot) {
    setState(() {
      _pendingMedia.remove(slot);
      _deletedSlots.add(slot);
      _captionControllers[slot]!.clear();
      _artworkTitleControllers[slot]?.clear();
    });
  }

  Future<void> _switchToAppreciator() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final destination = await ref
          .read(experienceSwitchRepositoryProvider)
          .switchToAppreciator();

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      widget.onSwitchedToAppreciator(destination);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage =
            'We could not switch experiences right now. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('maker_info_settings_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null && _data == null
            ? _LoadError(message: _errorMessage!, onRetry: _load)
            : _buildForm(),
      ),
      bottomNavigationBar: _loading || _data == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    key: const Key('maker_settings_save_close'),
                    onPressed: _saving ? null : _saveAndClose,
                    style: AppButtonStyles.outlineAction(),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.darkGray,
                            ),
                          )
                        : const Text(
                            'Save & Close',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    final data = _data!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 360 ? 18.0 : 20.0;

        return ListView(
          key: const Key('maker_settings_scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 28),
          children: [
            Text(
              'Maker Info Setting',
              style: AppTextStyles.onboardingHeading.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            _LabeledField(
              label: 'Name',
              keyName: 'maker_settings_name',
              controller: _nameController,
              hintText: 'Artist name',
            ),
            _LabeledField(
              label: 'Location',
              keyName: 'maker_settings_location',
              controller: _locationController,
              hintText: 'City/Zip code',
            ),
            _LabeledField(
              label: 'Statement',
              keyName: 'maker_settings_statement',
              controller: _statementController,
              hintText: 'Tell people about your work',
              minLines: 3,
              maxLines: 6,
            ),
            Text.rich(
              key: const Key('maker_settings_saved_count'),
              TextSpan(
                style: AppTextStyles.onboardingHelper.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(text: 'Your Profile Has Been Saved By '),
                  TextSpan(
                    text: '${data.savedCount}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' People'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Keyword',
              key: const Key('maker_settings_keyword_label'),
              style: AppTextStyles.onboardingHelper.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            _TaxonomySection(
              label: 'Type',
              options: data.availableTypes,
              selectedIds: _selectedTypes,
              keyPrefix: 'maker_settings_type',
              onToggle: (id) {
                setState(() {
                  _toggle(_selectedTypes, id);
                });
              },
            ),
            const SizedBox(height: 14),
            _TaxonomySection(
              label: 'Style',
              options: data.availableStyles,
              selectedIds: _selectedStyles,
              keyPrefix: 'maker_settings_style',
              onToggle: (id) {
                setState(() {
                  _toggle(_selectedStyles, id);
                });
              },
            ),
            const SizedBox(height: 18),
            _VisibilityField(
              label: 'Website',
              controller: _websiteController,
              keyName: 'maker_settings_website',
              hintText: 'www.artist.com',
              value: _showWebsite,
              onChanged: (value) {
                setState(() {
                  _showWebsite = value;
                });
              },
            ),
            _VisibilityField(
              label: 'Email',
              controller: _emailController,
              keyName: 'maker_settings_email',
              hintText: 'contact@artist.com',
              keyboardType: TextInputType.emailAddress,
              value: _showEmail,
              onChanged: (value) {
                setState(() {
                  _showEmail = value;
                });
              },
            ),
            _VisibilityOnlyRow(
              key: const Key('maker_settings_show_shows'),
              label: 'Current & Upcoming Shows',
              value: _showShows,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _showShows = value;
                      });
                    },
            ),
            const SizedBox(height: 24),
            Text(
              'Maker Info Content',
              style: AppTextStyles.onboardingHelper.copyWith(
                color: AppColors.primary,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            for (var slot = 1; slot <= 4; slot++) ...[
              _CarouselEditor(
                slot: slot,
                label: slot == 1
                    ? 'Content 1 (Salon Photo)'
                    : 'Content $slot (Artwork)',
                existing: _deletedSlots.contains(slot)
                    ? null
                    : _displayItem(data, slot),
                fallbackImageUrl: slot == 1 ? data.profileImageUrl : null,
                pending: _pendingMedia[slot],
                titleController: _artworkTitleControllers[slot],
                captionController: _captionControllers[slot]!,
                isArtwork: slot >= 2,
                moderationStatus: slot >= 2
                    ? _existingArtworkSlot(data, slot)?.artwork.moderationStatus
                    : null,
                onChoose: () => _chooseMedia(slot),
                onRemove: () => _removeSlot(slot),
              ),
              const SizedBox(height: 22),
            ],
            TextButton(
              key: const Key('maker_settings_switch_appreciator'),
              onPressed: _saving ? null : _switchToAppreciator,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.mutedText,
              ),
              child: const Text(
                'Switch to Appreciator',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                key: const Key('maker_settings_error'),
                style: const TextStyle(
                  color: AppColors.error,
                  fontFamily: AppTextStyles.fontFamily,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  static MakerCarouselItem? _existingItem(
    MakerInfoSettingsData? data,
    int slot,
  ) {
    if (data == null) return null;

    for (final item in data.carousel) {
      if (item.slot == slot) return item;
    }

    return null;
  }

  static MakerInfoArtworkSlot? _existingArtworkSlot(
    MakerInfoSettingsData? data,
    int slot,
  ) {
    if (data == null) return null;

    for (final item in data.artworkSlots) {
      if (item.slot == slot) return item;
    }

    return null;
  }

  static MakerCarouselItem? _displayItem(MakerInfoSettingsData data, int slot) {
    if (slot == 1) return _existingItem(data, 1);

    final artwork = _existingArtworkSlot(data, slot)?.artwork;
    if (artwork == null) return null;

    return MakerCarouselItem(
      id: artwork.id,
      slot: slot,
      kind: 'image',
      url: artwork.primaryImageUrl,
      caption: artwork.description,
    );
  }

  static void _toggle(Set<int> values, int id) {
    if (!values.add(id)) {
      values.remove(id);
    }
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.keyName,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String keyName;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: AppTextStyles.onboardingHelper.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 5),
          ],
          TextField(
            key: Key(keyName),
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            style: AppTextStyles.field,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.fieldHint,
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary50),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityField extends StatelessWidget {
  const _VisibilityField({
    required this.label,
    required this.controller,
    required this.keyName,
    required this.hintText,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String keyName;
  final String hintText;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.onboardingHelper.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 166,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Show on info page',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.onboardingHelper.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CompactVisibilityToggle(
                      key: Key('${keyName}_visibility'),
                      value: value,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _LabeledField(
            label: '',
            keyName: keyName,
            controller: controller,
            hintText: hintText,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }
}

class _VisibilityOnlyRow extends StatelessWidget {
  const _VisibilityOnlyRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.onboardingHelper.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CompactVisibilityToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CompactVisibilityToggle extends StatelessWidget {
  const _CompactVisibilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return Semantics(
      button: true,
      toggled: value,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 78,
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  value ? 'ON' : 'OFF',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 50,
                height: 28,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: 0.72,
                    alignment: Alignment.centerRight,
                    child: Switch(
                      value: value,
                      onChanged: enabled ? (_) {} : null,
                      activeThumbColor: AppColors.black,
                      activeTrackColor: AppColors.white,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxonomySection extends StatelessWidget {
  const _TaxonomySection({
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.keyPrefix,
    required this.onToggle,
  });

  final String label;
  final List<MakerSettingsTaxonomyOption> options;
  final Set<int> selectedIds;
  final String keyPrefix;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('${keyPrefix}_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.onboardingHelper.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              MaChoiceChip(
                key: Key('${keyPrefix}_${option.id}'),
                label: option.name,
                selected: selectedIds.contains(option.id),
                onTap: () => onToggle(option.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _CarouselEditor extends StatelessWidget {
  const _CarouselEditor({
    required this.slot,
    required this.label,
    required this.existing,
    required this.fallbackImageUrl,
    required this.pending,
    required this.titleController,
    required this.captionController,
    required this.isArtwork,
    required this.moderationStatus,
    required this.onChoose,
    required this.onRemove,
  });

  final int slot;
  final String label;
  final MakerCarouselItem? existing;
  final String? fallbackImageUrl;
  final PendingCarouselMedia? pending;
  final TextEditingController? titleController;
  final TextEditingController captionController;
  final bool isArtwork;
  final String? moderationStatus;
  final VoidCallback onChoose;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasRemovableMedia = pending != null || existing != null;

    return Column(
      key: Key('maker_settings_carousel_$slot'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.onboardingHelper.copyWith(
            color: AppColors.primary,
          ),
        ),
        Text(
          isArtwork
              ? 'Artwork image (JPG, PNG or WebP)'
              : 'image or video (15 seconds or less)',
          style: AppTextStyles.onboardingHelper.copyWith(
            fontSize: 9,
            color: AppColors.mutedText,
          ),
        ),
        if (isArtwork && moderationStatus != null) ...[
          const SizedBox(height: 2),
          Text(
            'Status: $moderationStatus',
            key: Key('maker_settings_artwork_status_$slot'),
            style: AppTextStyles.onboardingHelper.copyWith(
              fontSize: 9,
              color: AppColors.mutedText,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('maker_settings_carousel_pick_$slot'),
              onTap: onChoose,
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary50),
                ),
                clipBehavior: Clip.antiAlias,
                child: _CarouselPreview(
                  pending: pending,
                  existing: existing,
                  fallbackImageUrl: fallbackImageUrl,
                ),
              ),
            ),
            if (hasRemovableMedia) ...[
              const SizedBox(width: 10),
              IconButton(
                key: Key('maker_settings_carousel_remove_$slot'),
                onPressed: onRemove,
                tooltip: 'Remove content $slot',
                color: AppColors.mutedText,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (isArtwork && titleController != null) ...[
          Text(
            'Artwork title:',
            style: AppTextStyles.onboardingHelper.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: Key('maker_settings_artwork_title_$slot'),
            controller: titleController,
            maxLength: 180,
            style: AppTextStyles.field,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Artwork title',
              hintStyle: AppTextStyles.fieldHint,
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary50),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          isArtwork ? 'Artwork description:' : 'A sentence about the content:',
          style: AppTextStyles.onboardingHelper.copyWith(
            color: AppColors.primary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key('maker_settings_carousel_caption_$slot'),
          controller: captionController,
          maxLength: 280,
          style: AppTextStyles.field,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Optional Caption.',
            hintStyle: AppTextStyles.fieldHint,
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary50),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarouselPreview extends StatelessWidget {
  const _CarouselPreview({
    required this.pending,
    required this.existing,
    required this.fallbackImageUrl,
  });

  final PendingCarouselMedia? pending;
  final MakerCarouselItem? existing;
  final String? fallbackImageUrl;

  @override
  Widget build(BuildContext context) {
    if (pending != null) {
      if (pending!.kind == 'video') {
        return const _VideoPlaceholder();
      }

      return Image.memory(
        pending!.bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _AddPlaceholder();
        },
      );
    }

    if (existing != null) {
      if (existing!.isVideo) {
        return const _VideoPlaceholder();
      }

      final url = existing!.url ?? '';
      if (url.isNotEmpty) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const _AddPlaceholder();
          },
        );
      }
    }

    final fallback = fallbackImageUrl ?? '';
    if (fallback.isNotEmpty) {
      return Image.network(
        fallback,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _AddPlaceholder();
        },
      );
    }

    return const _AddPlaceholder();
  }
}

class _AddPlaceholder extends StatelessWidget {
  const _AddPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.add, color: AppColors.mutedText, size: 28),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: AppColors.primary,
          size: 36,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.onboardingHelper,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
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

enum _MediaChoice { image, video }
