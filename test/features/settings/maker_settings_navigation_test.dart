import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('Maker Settings nav item emits Maker-only settings index 4', (
    WidgetTester tester,
  ) async {
    var selectedIndex = -1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _EmptyDiscoveryRepository(),
          ),
        ],
        child: MaterialApp(
          home: MakerArtworkDiscoveryScreen(
            onBottomNavigationTap: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final settings = find.byKey(const Key('maker_nav_settings'));
    expect(settings, findsOneWidget);
    expect(settings.hitTestable(), findsOneWidget);

    await tester.tap(settings.hitTestable());
    await tester.pump();

    expect(selectedIndex, 4);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    return const DiscoveryArtworkPage(
      items: [],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 24, total: 0),
    );
  }
}
