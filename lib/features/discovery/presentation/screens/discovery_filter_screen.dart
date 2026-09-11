import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/artwork_discovery_controller.dart';
import '../../data/discovery_filter_repository.dart';
import '../../domain/discovery_artwork.dart';
import '../../domain/discovery_filter_models.dart';
import '../../domain/discovery_query.dart';

class DiscoveryFilterScreen extends ConsumerStatefulWidget {
  const DiscoveryFilterScreen({super.key, this.onClose, this.onApplied});

  final VoidCallback? onClose;
  final VoidCallback? onApplied;

  @override
  ConsumerState<DiscoveryFilterScreen> createState() =>
      _DiscoveryFilterScreenState();
}

class _DiscoveryFilterScreenState extends ConsumerState<DiscoveryFilterScreen> {
  late final TextEditingController _locationSearchController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;

  DiscoveryFilterOptions? _options;
  DiscoveryLocation? _selectedLocation;
  List<DiscoveryLocation> _locationSuggestions = const <DiscoveryLocation>[];

  late Set<int> _selectedTypeIds;
  late Set<int> _selectedStyleIds;
  late Set<String> _selectedStatuses;

  bool _loadingOptions = true;
  bool _loadingLocations = false;
  bool _applying = false;
  bool _useRadius = false;
  double _radiusKm = 25;
  String? _errorMessage;
  Timer? _locationDebounce;

  @override
  void initState() {
    super.initState();

    final query = ref.read(discoveryQueryProvider);

    _selectedTypeIds = Set<int>.from(query.typeIds);
    _selectedStyleIds = Set<int>.from(query.styleIds);
    _selectedStatuses = Set<String>.from(query.showStatuses);

    if (query.locationId != null && query.locationLabel != null) {
      _selectedLocation = DiscoveryLocation(
        id: query.locationId!,
        label: query.locationLabel!,
        countryCode: query.countryCode,
        latitude: query.latitude,
        longitude: query.longitude,
      );
    }

    _useRadius =
        query.latitude != null &&
        query.longitude != null &&
        query.radiusKm != null;
    _radiusKm = query.radiusKm ?? 25;

    _locationSearchController = TextEditingController(
      text: query.locationLabel ?? '',
    );
    _cityController = TextEditingController(text: query.city);
    _postalController = TextEditingController(text: query.postalCode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _locationSearchController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await ref
          .read(discoveryFilterRepositoryProvider)
          .fetchOptions();

      if (!mounted) return;

      setState(() {
        _options = options;
        _loadingOptions = false;
        _radiusKm = _radiusKm
            .clamp(options.radiusMinKm, options.radiusMaxKm)
            .toDouble();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingOptions = false;
        _errorMessage = 'Filter options could not be loaded. Please try again.';
      });
    }
  }

  void _searchLocations(String value) {
    _locationDebounce?.cancel();
    final text = value.trim();

    if (text.isEmpty) {
      setState(() {
        _selectedLocation = null;
        _locationSuggestions = const <DiscoveryLocation>[];
        _loadingLocations = false;
      });
      return;
    }

    if (_selectedLocation?.label == text) return;

    setState(() {
      _selectedLocation = null;
    });

    _locationDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadLocations(text),
    );
  }

  Future<void> _loadLocations(String text) async {
    if (!mounted) return;

    setState(() {
      _loadingLocations = true;
    });

    try {
      final page = await ref
          .read(discoveryFilterRepositoryProvider)
          .searchLocations(text);

      if (!mounted || _locationSearchController.text.trim() != text.trim()) {
        return;
      }

      setState(() {
        _locationSuggestions = page.items;
        _loadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationSuggestions = const <DiscoveryLocation>[];
        _loadingLocations = false;
      });
    }
  }

  void _selectLocation(DiscoveryLocation location) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedLocation = location;
      _locationSearchController.text = location.label;
      _locationSuggestions = const <DiscoveryLocation>[];
      _cityController.clear();
      _postalController.clear();

      if (location.latitude == null || location.longitude == null) {
        _useRadius = false;
      }
    });
  }

  void _toggleType(int id) {
    setState(() {
      _selectedTypeIds.contains(id)
          ? _selectedTypeIds.remove(id)
          : _selectedTypeIds.add(id);
    });
  }

  void _toggleStyle(int id) {
    setState(() {
      _selectedStyleIds.contains(id)
          ? _selectedStyleIds.remove(id)
          : _selectedStyleIds.add(id);
    });
  }

  void _toggleStatus(String value) {
    setState(() {
      _selectedStatuses.contains(value)
          ? _selectedStatuses.remove(value)
          : _selectedStatuses.add(value);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedTypeIds.clear();
      _selectedStyleIds.clear();
      _selectedStatuses.clear();
      _selectedLocation = null;
      _locationSuggestions = const <DiscoveryLocation>[];
      _locationSearchController.clear();
      _cityController.clear();
      _postalController.clear();
      _useRadius = false;
      _radiusKm = 25;
      _errorMessage = null;
    });
  }

  Future<void> _apply() async {
    if (_applying) return;

    final location = _selectedLocation;
    final canUseRadius =
        _useRadius && location?.latitude != null && location?.longitude != null;

    final query = DiscoveryQuery(
      typeIds: Set<int>.from(_selectedTypeIds),
      styleIds: Set<int>.from(_selectedStyleIds),
      showStatuses: Set<String>.from(_selectedStatuses),
      locationId: canUseRadius ? null : location?.id,
      locationLabel: location?.label,
      city: _cityController.text.trim(),
      postalCode: _postalController.text.trim(),
      countryCode: location?.countryCode,
      latitude: canUseRadius ? location!.latitude : null,
      longitude: canUseRadius ? location!.longitude : null,
      radiusKm: canUseRadius ? _radiusKm : null,
    );

    setState(() {
      _applying = true;
      _errorMessage = null;
    });

    ref.read(discoveryQueryProvider.notifier).setQuery(query);

    await ref
        .read(artworkDiscoveryControllerProvider.notifier)
        .applyQuery(query);

    if (!mounted) return;

    setState(() {
      _applying = false;
    });

    widget.onApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return Scaffold(
      key: const Key('discovery_filter_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('filter_close_button'),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.primary,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.onboardingHeading.copyWith(
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('filter_clear_button'),
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'Clear all',
                      maxLines: 1,
                      style: AppTextStyles.onboardingHelper.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingOptions
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : options == null
                  ? _LoadError(
                      message:
                          _errorMessage ?? 'Filter options are unavailable.',
                      onRetry: _loadOptions,
                    )
                  : _buildForm(options),
            ),
            if (options != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const Key('filter_apply_button'),
                      onPressed: _applying ? null : _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: _applying
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.black,
                              ),
                            )
                          : const Text(
                              'Apply Filters',
                              style: AppTextStyles.buttonDark,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(DiscoveryFilterOptions options) {
    final location = _selectedLocation;
    final canUseRadius =
        location?.latitude != null && location?.longitude != null;

    return ListView(
      key: const Key('filter_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _sectionTitle('Type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in options.types)
              _ChoicePill(
                key: Key('filter_type_${type.id}'),
                label: type.name,
                selected: _selectedTypeIds.contains(type.id),
                onTap: () => _toggleType(type.id),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _sectionTitle('Style'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final style in options.styles)
              _ChoicePill(
                key: Key('filter_style_${style.id}'),
                label: style.name,
                selected: _selectedStyleIds.contains(style.id),
                onTap: () => _toggleStyle(style.id),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _sectionTitle('Show Status'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in options.showStatuses)
              _ChoicePill(
                key: Key('filter_status_${status.value}'),
                label: status.label,
                selected: _selectedStatuses.contains(status.value),
                onTap: () => _toggleStatus(status.value),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _sectionTitle('Location'),
        TextField(
          key: const Key('filter_location_search'),
          controller: _locationSearchController,
          onChanged: _searchLocations,
          style: AppTextStyles.field.copyWith(fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: _inputDecoration(
            hintText: 'Search city, region or ZIP / postal code',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
            suffixIcon: _loadingLocations
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (_locationSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              key: const Key('filter_location_suggestions'),
              color: AppColors.inputFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.primary50),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final suggestion in _locationSuggestions.take(8))
                    ListTile(
                      key: Key('location_suggestion_${suggestion.id}'),
                      dense: true,
                      title: Text(
                        suggestion.label,
                        style: AppTextStyles.onboardingHelper.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      onTap: () => _selectLocation(suggestion),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('filter_city_field'),
                controller: _cityController,
                style: AppTextStyles.field.copyWith(fontSize: 16),
                cursorColor: AppColors.primary,
                decoration: _inputDecoration(hintText: 'City'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('filter_postal_field'),
                controller: _postalController,
                style: AppTextStyles.field.copyWith(fontSize: 16),
                cursorColor: AppColors.primary,
                decoration: _inputDecoration(hintText: 'ZIP / Postal'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          key: const Key('filter_radius_switch'),
          contentPadding: EdgeInsets.zero,
          value: _useRadius && canUseRadius,
          onChanged: canUseRadius
              ? (value) {
                  setState(() {
                    _useRadius = value;
                  });
                }
              : null,
          activeThumbColor: AppColors.primary,
          title: Text(
            'Use radius around selected location',
            style: AppTextStyles.onboardingHelper.copyWith(
              color: canUseRadius ? AppColors.white : AppColors.mutedText,
            ),
          ),
          subtitle: !canUseRadius
              ? const Text(
                  'Select a location with coordinates to use distance.',
                  style: AppTextStyles.onboardingHelper,
                )
              : null,
        ),
        if (_useRadius && canUseRadius) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Radius',
                style: AppTextStyles.onboardingHelper.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_radiusKm.round()} km',
                key: const Key('filter_radius_value'),
                style: AppTextStyles.onboardingHelper.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          Slider(
            key: const Key('filter_radius_slider'),
            value: _radiusKm
                .clamp(options.radiusMinKm, options.radiusMaxKm)
                .toDouble(),
            min: options.radiusMinKm,
            max: options.radiusMaxKm,
            divisions: _radiusDivisions(options),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary50,
            onChanged: (value) {
              setState(() {
                _radiusKm = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.onboardingHelper.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static int? _radiusDivisions(DiscoveryFilterOptions options) {
    final span = (options.radiusMaxKm - options.radiusMinKm).round();
    if (span <= 0) return null;
    return span > 100 ? 100 : span;
  }

  static InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.fieldHint.copyWith(fontSize: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.inputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary50),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(
            label,
            style: selected ? AppTextStyles.chipSelected : AppTextStyles.chip,
          ),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
