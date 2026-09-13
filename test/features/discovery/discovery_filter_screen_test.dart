import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/data/discovery_filter_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_filter_models.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/discovery_filter_screen.dart';

void main() {
  testWidgets('applies taxonomy, status and radius filters', (tester) async {
    final artworkRepository = _FakeArtworkRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryFilterRepositoryProvider.overrideWithValue(
            _FakeFilterRepository(),
          ),
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            artworkRepository,
          ),
        ],
        child: MaterialApp(
          home: DiscoveryFilterScreen(onClose: () {}, onApplied: () {}),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final filterScrollable = _verticalFilterScrollable();
    expect(filterScrollable, findsOneWidget);

    await tester.tap(find.byKey(const Key('filter_type_1')));
    await tester.tap(find.byKey(const Key('filter_style_2')));
    await tester.tap(find.byKey(const Key('filter_status_current')));

    final locationSearch = find.byKey(const Key('filter_location_search'));
    await tester.scrollUntilVisible(
      locationSearch,
      220,
      scrollable: filterScrollable,
    );

    await tester.enterText(locationSearch, '10001');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    final suggestion = find.byKey(const Key('location_suggestion_7'));
    await tester.scrollUntilVisible(
      suggestion,
      180,
      scrollable: filterScrollable,
    );
    expect(suggestion, findsOneWidget);

    await tester.tap(suggestion);
    await tester.pump();

    final radiusValue = find.byKey(const Key('filter_radius_value'));
    await tester.scrollUntilVisible(
      radiusValue,
      160,
      scrollable: filterScrollable,
    );
    expect(radiusValue, findsOneWidget);

    final applyButton = find.byKey(const Key('filter_apply_button'));
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pump();
    await tester.pumpAndSettle();

    final query = artworkRepository.lastQuery;
    expect(query, isNotNull);
    expect(query!.typeIds, <int>{1});
    expect(query.styleIds, <int>{2});
    expect(query.showStatuses, <String>{'current'});
    expect(query.latitude, 40.7128);
    expect(query.longitude, -74.0060);
    expect(query.radiusKm, isNotNull);
    expect(query.locationId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter is responsive and scrollable on compact viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryFilterRepositoryProvider.overrideWithValue(
            _FakeFilterRepository(),
          ),
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _FakeArtworkRepository(),
          ),
        ],
        child: MaterialApp(
          home: DiscoveryFilterScreen(onClose: () {}, onApplied: () {}),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('filter_clear_button')), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('discovery_filter_screen')),
    );
    expect(scaffold.backgroundColor, const Color(0xFF020101));
    expect(tester.takeException(), isNull);

    final filterScrollable = _verticalFilterScrollable();
    expect(filterScrollable, findsOneWidget);

    final locationSearch = find.byKey(const Key('filter_location_search'));
    await tester.scrollUntilVisible(
      locationSearch,
      180,
      scrollable: filterScrollable,
    );

    await tester.enterText(locationSearch, '10001');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    final suggestion = find.byKey(const Key('location_suggestion_7'));
    await tester.scrollUntilVisible(
      suggestion,
      150,
      scrollable: filterScrollable,
    );
    expect(suggestion, findsOneWidget);

    await tester.tap(suggestion);
    await tester.pump();

    final radiusSlider = find.byKey(const Key('filter_radius_slider'));
    await tester.scrollUntilVisible(
      radiusSlider,
      180,
      scrollable: filterScrollable,
    );

    expect(radiusSlider, findsOneWidget);
    expect(find.text('Radius (miles)'), findsOneWidget);

    final locationField = tester.widget<TextField>(locationSearch);
    expect(locationField.decoration?.fillColor, const Color(0xFF0E071A));
    expect(tester.takeException(), isNull);
  });

  testWidgets('location suggestions paint on a Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryFilterRepositoryProvider.overrideWithValue(
            _FakeFilterRepository(),
          ),
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _FakeArtworkRepository(),
          ),
        ],
        child: const MaterialApp(home: DiscoveryFilterScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    final filterScrollable = _verticalFilterScrollable();
    final locationSearch = find.byKey(const Key('filter_location_search'));

    await tester.scrollUntilVisible(
      locationSearch,
      220,
      scrollable: filterScrollable,
    );

    await tester.enterText(locationSearch, '10001');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(
      find.byKey(const Key('filter_location_suggestions')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('location_suggestion_7')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _verticalFilterScrollable() {
  return find.descendant(
    of: find.byKey(const Key('filter_scroll')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
      description: 'vertical Filter ListView Scrollable',
    ),
  );
}

class _FakeFilterRepository implements DiscoveryFilterRepositoryContract {
  @override
  Future<DiscoveryFilterOptions> fetchOptions() async {
    return const DiscoveryFilterOptions(
      types: <DiscoveryTaxonomy>[
        DiscoveryTaxonomy(id: 1, name: 'Painting', slug: 'painting'),
      ],
      styles: <DiscoveryTaxonomy>[
        DiscoveryTaxonomy(id: 2, name: 'Minimal', slug: 'minimal'),
      ],
      showStatuses: <DiscoveryShowStatusOption>[
        DiscoveryShowStatusOption(
          value: 'current',
          label: 'Currently Showing Work',
        ),
      ],
      radiusMinKm: 1,
      radiusMaxKm: 500,
    );
  }

  @override
  Future<DiscoveryLocationPage> searchLocations(
    String search, {
    int page = 1,
    int perPage = 20,
    String? countryCode,
  }) async {
    return const DiscoveryLocationPage(
      items: <DiscoveryLocation>[
        DiscoveryLocation(
          id: 7,
          label: 'New York, NY 10001',
          city: 'New York',
          region: 'NY',
          postalCode: '10001',
          countryCode: 'US',
          latitude: 40.7128,
          longitude: -74.0060,
        ),
      ],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 1),
    );
  }
}

class _FakeArtworkRepository implements ArtworkDiscoveryRepositoryContract {
  DiscoveryQuery? lastQuery;

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    lastQuery = query;

    return const DiscoveryArtworkPage(
      items: <DiscoveryArtwork>[],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 24, total: 0),
    );
  }
}
