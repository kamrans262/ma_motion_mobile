import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/appreciator_artwork_discovery_screen.dart';
import 'package:ma_motion_mobile/features/settings/data/appreciator_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/appreciator_settings_models.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'Appreciator bottom Settings icon opens modal over discovery grid',
    (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _EmptyDiscoveryRepository(),
          ),
          appreciatorSettingsRepositoryProvider.overrideWithValue(
            _FakeAppreciatorSettingsRepository(),
          ),
          experienceSwitchRepositoryProvider.overrideWithValue(
            _FakeExperienceSwitchRepository(),
          ),
        ],
        child: const MaterialApp(home: AppreciatorArtworkDiscoveryScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    final settings = find.byKey(const Key('maker_nav_settings'));
    expect(settings, findsOneWidget);
    expect(settings.hitTestable(), findsOneWidget);

    await tester.tap(settings.hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maker_artwork_discovery_screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('appreciator_settings_card')), findsOneWidget);
    expect(
      find.byKey(const Key('appreciator_settings_heading')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    },
  );
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

class _FakeAppreciatorSettingsRepository
    implements AppreciatorSettingsRepositoryContract {
  @override
  Future<AppreciatorSettingsData> load() async {
    return const AppreciatorSettingsData(
      name: 'Ari Viewer',
      email: 'ari@example.com',
      locationText: 'New York, NY',
      locationId: 8,
      onboardingCompleted: true,
    );
  }

  @override
  Future<int?> resolveLocationId(String query) async => 8;

  @override
  Future<AppreciatorSettingsData> save(AppreciatorSettingsDraft draft) async {
    return AppreciatorSettingsData(
      name: draft.name,
      email: draft.email,
      locationText: draft.locationText,
      locationId: draft.locationId,
      onboardingCompleted: true,
    );
  }
}

class _FakeExperienceSwitchRepository
    implements ExperienceSwitchRepositoryContract {
  @override
  Future<MakerEntryDestination> switchToAppreciator() async {
    return MakerEntryDestination.appreciatorDiscovery;
  }

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    return MakerEntryDestination.discovery;
  }
}
