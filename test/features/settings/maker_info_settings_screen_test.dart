import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/settings/data/maker_info_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/maker_info_settings_models.dart';
import 'package:ma_motion_mobile/features/settings/presentation/screens/maker_info_settings_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
    'renders Maker Info Setting and saves profile changes',
    (WidgetTester tester) async {
      final repository = _FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: MakerInfoSettingsScreen(
              onClose: () {
                repository.closeCalls++;
              },
              onSwitchedToAppreciator: _noop,
            ),
          ),
        ),
      );

      await _finishInitialLoad(tester);

      expect(find.text('Maker Info Setting'), findsOneWidget);
      expect(
        find.byKey(const Key('maker_settings_saved_count')),
        findsOneWidget,
      );
      expect(find.textContaining('37 People'), findsOneWidget);

      final settingsList = find.byKey(const Key('maker_settings_scroll'));
      expect(settingsList, findsOneWidget);

      final emailSwitch = find.byKey(
        const Key('maker_settings_email_visibility'),
      );
      await _scrollIntoSafeTapRegion(
        tester,
        target: emailSwitch,
        scrollView: settingsList,
      );

      await tester.tap(emailSwitch.hitTestable());
      await tester.pump();
      expect(tester.widget<Switch>(emailSwitch).value, isTrue);

      expect(
        find.byKey(const Key('maker_settings_save_close')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('maker_settings_save_close')),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(repository.lastDraft?.locationId, 3);
      expect(repository.lastDraft?.showEmail, isTrue);
      expect(repository.closeCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Maker settings has no overflow on 320x520 viewport',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 520));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: MakerInfoSettingsScreen(
              onClose: _noop,
              onSwitchedToAppreciator: _noop,
            ),
          ),
        ),
      );

      await _finishInitialLoad(tester);

      expect(find.text('Maker Info Setting'), findsOneWidget);
      expect(
        find.byKey(const Key('maker_settings_save_close')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final settingsList = find.byKey(const Key('maker_settings_scroll'));
      expect(settingsList, findsOneWidget);

      await tester.dragUntilVisible(
        find.byKey(const Key('maker_settings_carousel_3')),
        settingsList,
        const Offset(0, -300),
      );

      expect(
        find.byKey(const Key('maker_settings_carousel_3')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Switch to Appreciator logs out and invokes role-selection navigation',
    (WidgetTester tester) async {
      final repository = _FakeSettingsRepository();
      var switched = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: MakerInfoSettingsScreen(
              onClose: _noop,
              onSwitchedToAppreciator: () {
                switched++;
              },
            ),
          ),
        ),
      );

      await _finishInitialLoad(tester);

      final settingsList = find.byKey(const Key('maker_settings_scroll'));

      final switchRole = find.byKey(
        const Key('maker_settings_switch_appreciator'),
      );
      await _scrollIntoSafeTapRegion(
        tester,
        target: switchRole,
        scrollView: settingsList,
      );

      await tester.tap(switchRole.hitTestable());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 1);
      expect(switched, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'caption text alone does not create an empty carousel media slot',
    (WidgetTester tester) async {
      final repository = _FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: MakerInfoSettingsScreen(
              onClose: () {
                repository.closeCalls++;
              },
              onSwitchedToAppreciator: _noop,
            ),
          ),
        ),
      );

      await _finishInitialLoad(tester);

      final settingsList = find.byKey(const Key('maker_settings_scroll'));
      final caption = find.byKey(
        const Key('maker_settings_carousel_caption_2'),
      );

      await _scrollIntoSafeTapRegion(
        tester,
        target: caption,
        scrollView: settingsList,
      );

      await tester.enterText(caption, 'Caption without selected media');
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('maker_settings_save_close')),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(repository.saveCarouselCalls, 0);
      expect(repository.deleteCarouselCalls, 0);
      expect(repository.closeCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _scrollIntoSafeTapRegion(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollView,
}) async {
  await tester.dragUntilVisible(
    target,
    scrollView,
    const Offset(0, -240),
  );
  await tester.pump();

  await Scrollable.ensureVisible(
    tester.element(target),
    alignment: 0.30,
    duration: Duration.zero,
  );
  await tester.pump();

  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _finishInitialLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void _noop() {}

class _FakeSettingsRepository
    implements MakerInfoSettingsRepositoryContract {
  int saveCalls = 0;
  int closeCalls = 0;
  int logoutCalls = 0;
  int saveCarouselCalls = 0;
  int deleteCarouselCalls = 0;
  MakerInfoSettingsDraft? lastDraft;

  @override
  Future<MakerInfoSettingsData> load() async {
    return const MakerInfoSettingsData(
      name: 'Artist Ken',
      bio: 'A contemporary artist exploring form and color.',
      locationText: 'Chicago, IL',
      website: 'https://artist.example',
      email: 'contact@artist.example',
      profileImageUrl: null,
      managedLocationId: 3,
      showWebsite: true,
      showEmail: false,
      showShows: true,
      selectedTypeIds: <int>{1},
      selectedStyleIds: <int>{2},
      carousel: <MakerCarouselItem>[],
      savedCount: 37,
      availableTypes: <MakerSettingsTaxonomyOption>[
        MakerSettingsTaxonomyOption(
          id: 1,
          name: 'Painting',
          slug: 'painting',
        ),
      ],
      availableStyles: <MakerSettingsTaxonomyOption>[
        MakerSettingsTaxonomyOption(
          id: 2,
          name: 'Contemporary',
          slug: 'contemporary',
        ),
      ],
    );
  }

  @override
  Future<void> saveProfile(MakerInfoSettingsDraft draft) async {
    saveCalls++;
    lastDraft = draft;
  }

  @override
  Future<MakerCarouselItem> saveCarouselSlot({
    required int slot,
    required String? caption,
    Uint8List? bytes,
    String? fileName,
  }) async {
    saveCarouselCalls++;

    return MakerCarouselItem(
      slot: slot,
      kind: 'image',
      caption: caption,
    );
  }

  @override
  Future<void> deleteCarouselSlot(int slot) async {
    deleteCarouselCalls++;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}
