import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_button_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_centered_taxonomy_label.dart';
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
  static const double _kmPerMile = 1.609344;
  static const double _defaultRadiusMiles = 25;
  static const double _maxRadiusMiles = 200;

  late final TextEditingController _locationSearchController;

  DiscoveryFilterOptions? _options;
  DiscoveryLocation? _selectedLocation;
  List<DiscoveryLocation> _locationSuggestions = const <DiscoveryLocation>[];

  late Set<int> _selectedTypeIds;
  late Set<int> _selectedStyleIds;
  late Set<String> _selectedStatuses;

  bool _loadingOptions = true;
  bool _loadingLocations = false;
  bool _applying = false;
  double _radiusMiles = _defaultRadiusMiles;
  String? _errorMessage;
  Timer? _locationDebounce;

  @override
  void initState() {
    super.initState();

    final query = ref.read(discoveryQueryProvider);

    _selectedTypeIds = Set<int>.from(query.typeIds);
    _selectedStyleIds = Set<int>.from(query.styleIds);
    _selectedStatuses = Set<String>.from(query.showStatuses)..remove('past');

    final locationLabel = query.locationLabel?.trim() ?? '';
    if (locationLabel.isNotEmpty &&
        (query.locationId != null ||
            query.latitude != null ||
            query.longitude != null)) {
      _selectedLocation = DiscoveryLocation(
        id: query.locationId ?? 0,
        label: locationLabel,
        countryCode: query.countryCode,
        latitude: query.latitude,
        longitude: query.longitude,
      );
    }

    _radiusMiles = query.radiusKm == null
        ? _defaultRadiusMiles
        : _kmToMiles(query.radiusKm!);

    final initialLocationText = locationLabel.isNotEmpty
        ? locationLabel
        : query.postalCode.trim().isNotEmpty
        ? query.postalCode
        : query.city;

    _locationSearchController = TextEditingController(
      text: initialLocationText,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _locationSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await ref
          .read(discoveryFilterRepositoryProvider)
          .fetchOptions();

      if (!mounted) return;

      final minMiles = _kmToMiles(options.radiusMinKm);
      final maxMiles = _kmToMiles(options.radiusMaxKm)
          .clamp(minMiles, _maxRadiusMiles)
          .toDouble();

      setState(() {
        _options = options;
        _loadingOptions = false;
        _radiusMiles = _radiusMiles.clamp(minMiles, maxMiles).toDouble();
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
      _radiusMiles = _defaultRadiusMiles;
      _errorMessage = null;
    });
  }

  Future<void> _apply() async {
    if (_applying) return;

    final location = _selectedLocation;
    final rawLocation = _locationSearchController.text.trim();
    final canUseRadius =
        location?.latitude != null && location?.longitude != null;
    final looksPostal = _looksLikePostal(rawLocation);

    final query = DiscoveryQuery(
      typeIds: Set<int>.from(_selectedTypeIds),
      styleIds: Set<int>.from(_selectedStyleIds),
      showStatuses: Set<String>.from(_selectedStatuses),
      locationId: canUseRadius
          ? null
          : location != null && location.id > 0
          ? location.id
          : null,
      locationLabel:
          location?.label ?? (rawLocation.isEmpty ? null : rawLocation),
      city: location == null && rawLocation.isNotEmpty && !looksPostal
          ? rawLocation
          : '',
      postalCode: location == null && looksPostal ? rawLocation : '',
      countryCode: location?.countryCode,
      latitude: canUseRadius ? location!.latitude : null,
      longitude: canUseRadius ? location!.longitude : null,
      radiusKm: canUseRadius ? _milesToKm(_radiusMiles) : null,
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
      backgroundColor: AppColors.artworkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.onboardingHeading.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    key: const Key('filter_clear_button'),
                    onTap: _clearAll,
                    overlayColor: AppButtonStyles.purpleInkOverlay,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 8,
                      ),
                      child: Text(
                        'Clear Filters',
                        style: AppTextStyles.onboardingHelper.copyWith(
                          color: AppColors.darkGray,
                          fontSize: 14,
                        ),
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('filter_apply_button'),
                      onPressed: _applying ? null : _apply,
                      style: AppButtonStyles.filterAction(),
                      child: _applying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.darkGray,
                              ),
                            )
                          : Transform.translate(
                              offset: const Offset(0, 1),
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  height: 1.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
    final minMiles = _kmToMiles(options.radiusMinKm);
    final maxMiles = _kmToMiles(options.radiusMaxKm)
        .clamp(minMiles, _maxRadiusMiles)
        .toDouble();
    final radiusValue = _radiusMiles.clamp(minMiles, maxMiles).toDouble();

    return ListView(
      key: const Key('filter_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      children: [
        _sectionTitle('Type'),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            for (final type in options.types)
              _ChoicePill(
                key: Key('filter_type_${type.id}'),
                label: type.name,
                selected: _selectedTypeIds.contains(type.id),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                darkBackground: true,
                onTap: () => _toggleType(type.id),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle('Style'),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            for (final style in options.styles)
              _ChoicePill(
                key: Key('filter_style_${style.id}'),
                label: style.name,
                selected: _selectedStyleIds.contains(style.id),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                darkBackground: true,
                onTap: () => _toggleStyle(style.id),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle('Show Status'),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            for (final status in options.showStatuses)
              if (status.value != 'past')
                _ChoicePill(
                  key: Key('filter_status_${status.value}'),
                  label: status.label,
                  selected: _selectedStatuses.contains(status.value),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  darkBackground: true,
                  onTap: () => _toggleStatus(status.value),
                ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionTitle('Location'),
        TextField(
          key: const Key('filter_location_search'),
          controller: _locationSearchController,
          onChanged: _searchLocations,
          style: AppTextStyles.field.copyWith(fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: _inputDecoration(
            hintText: 'Enter City or ZIP Code',
            suffixIcon: _loadingLocations
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
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
              color: AppColors.filterInputFill,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.primary),
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
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _selectLocation(suggestion),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          'Radius (miles)',
          style: AppTextStyles.onboardingHelper.copyWith(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          key: const Key('filter_radius_control_row'),
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 1,
                  activeTrackColor: AppColors.white,
                  inactiveTrackColor: AppColors.darkGray,
                  thumbColor: AppColors.white,
                  overlayColor: AppColors.primary50,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 5,
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  key: const Key('filter_radius_slider'),
                  value: radiusValue,
                  min: minMiles,
                  max: maxMiles,
                  divisions: _radiusDivisions(minMiles, maxMiles),
                  onChanged: (value) {
                    setState(() {
                      _radiusMiles = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 36,
              child: Text(
                '${radiusValue.round()}',
                key: const Key('filter_radius_value'),
                textAlign: TextAlign.right,
                style: AppTextStyles.onboardingHelper.copyWith(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.onboardingHelper.copyWith(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.fieldHint.copyWith(
        color: AppColors.darkGray,
        fontSize: 16,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.filterInputFill,
      contentPadding: const EdgeInsets.fromLTRB(14, 21, 14, 7),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }

  static int? _radiusDivisions(double minMiles, double maxMiles) {
    final span = (maxMiles - minMiles).round();
    if (span <= 0) return null;
    return span > 100 ? 100 : span;
  }

  static bool _looksLikePostal(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;

    return RegExp(r'\d').hasMatch(text);
  }

  static double _kmToMiles(double kilometers) => kilometers / _kmPerMile;

  static double _milesToKm(double miles) => miles * _kmPerMile;
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize = 14,
    this.fontWeight,
    this.darkBackground = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;
  final FontWeight? fontWeight;
  final bool darkBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.white
          : darkBackground
          ? const Color(0xFF020202)
          : AppColors.savedBackground,
      child: InkWell(
        onTap: onTap,
        overlayColor: AppButtonStyles.purpleInkOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.white : AppColors.darkGray,
              width: 0.8,
            ),
          ),
          child: MaCenteredTaxonomyLabel(
            label: label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: fontSize,
              height: 1.1,
              fontWeight: fontWeight ?? FontWeight.w500,
              color: selected ? AppColors.black : AppColors.white,
            ),
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
              style: AppButtonStyles.outlineAction(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
