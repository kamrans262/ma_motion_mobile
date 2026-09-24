import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/widgets/ma_centered_taxonomy_label.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/settings/data/maker_info_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/maker_info_settings_models.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_choice_chip.dart';
import 'package:ma_motion_mobile/features/settings/presentation/screens/maker_info_settings_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('renders Maker Info Setting and saves profile changes', (
    WidgetTester tester,
  ) async {
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
            onSwitchedToAppreciator: _noopDestination,
          ),
        ),
      ),
    );

    await _finishInitialLoad(tester);

    final settings = tester.widget<Scaffold>(
      find.byKey(const Key('maker_info_settings_screen')),
    );
    expect(settings.backgroundColor, AppColors.artworkBackground);
    for (final fieldKey in <String>[
      'maker_settings_name',
      'maker_settings_location',
      'maker_settings_statement',
    ]) {
      final field = tester.widget<TextField>(find.byKey(Key(fieldKey)));
      expect(field.decoration?.fillColor, AppColors.filterInputFill);
    }
    final save = tester.widget<OutlinedButton>(
      find.byKey(const Key('maker_settings_save_close')),
    );
    expect(
      save.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF020202),
    );
    expect(
      save.style?.backgroundColor?.resolve(<WidgetState>{WidgetState.pressed}),
      AppColors.primary,
    );
    expect(save.style?.side?.resolve(<WidgetState>{})?.width, 1);
    expect(
      tester.getSize(find.byKey(const Key('maker_settings_save_close'))).height,
      48,
    );
    expect(tester.widget<Text>(find.text('Save & Close')).style?.fontSize, 16);

    for (final choice in <(String, String)>[
      ('maker_settings_type_1', 'Painting'),
      ('maker_settings_style_2', 'Contemporary'),
    ]) {
      final chip = tester.widget<MaChoiceChip>(find.byKey(Key(choice.$1)));
      expect(chip.unselectedBackgroundColor, const Color(0xFF020202));
      final center = tester.getCenter(find.byKey(Key(choice.$1)));
      final textCenter = tester.getCenter(find.text(choice.$2));
      expect(textCenter.dx, closeTo(center.dx, 1));
      expect(
        tester.widget<Text>(find.text(choice.$2)).style?.color,
        AppColors.white,
      );
      expect(
        textCenter.dy,
        closeTo(center.dy + MaCenteredTaxonomyLabel.opticalOffsetY, 1),
      );
    }

    expect(find.text('Maker Info Setting'), findsOneWidget);
    expect(find.byKey(const Key('maker_settings_saved_count')), findsOneWidget);
    final savedCount = tester.widget<Text>(
      find.byKey(const Key('maker_settings_saved_count')),
    );
    final savedSpan = savedCount.textSpan! as TextSpan;
    final countSpan = savedSpan.children![1] as TextSpan;
    expect(countSpan.text, '37');
    expect(countSpan.style?.color, Colors.white);

    final keyword = tester.widget<Text>(
      find.byKey(const Key('maker_settings_keyword_label')),
    );
    final nameLabel = tester.widgetList<Text>(find.text('Name')).first;
    expect(keyword.style?.fontSize, nameLabel.style?.fontSize);
    expect(keyword.style?.fontWeight, nameLabel.style?.fontWeight);

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

    final legalTerms = find.byKey(const Key('maker_settings_terms_text'));
    await tester.dragUntilVisible(
      legalTerms,
      settingsList,
      const Offset(0, -240),
    );
    await tester.pump();
    expect(legalTerms, findsOneWidget);
    final legalPrivacy = find.byKey(const Key('maker_settings_privacy_text'));
    final deleteAccount = find.byKey(
      const Key('maker_settings_delete_account'),
    );
    expect(legalPrivacy, findsOneWidget);
    expect(deleteAccount, findsOneWidget);
    expect(
      tester.widget<Text>(legalTerms).style?.color,
      AppColors.darkGray,
    );
    expect(
      tester.widget<Text>(legalPrivacy).style?.color,
      AppColors.darkGray,
    );
    expect(
      tester.getTopLeft(legalPrivacy).dy,
      greaterThan(tester.getTopLeft(legalTerms).dy),
    );
    expect(
      tester.getTopLeft(deleteAccount).dy,
      greaterThan(tester.getTopLeft(legalPrivacy).dy),
    );
    final deleteText = tester.widget<Text>(
      find.descendant(of: deleteAccount, matching: find.byType(Text)),
    );
    expect(deleteText.style?.color, AppColors.darkGray);
    expect(deleteText.style?.decorationColor, AppColors.darkGray);
    expect(tester.widget<Text>(legalTerms).style?.decoration, TextDecoration.underline);
    expect(tester.widget<Text>(legalPrivacy).style?.decoration, TextDecoration.underline);
    final switchText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('maker_settings_switch_appreciator')),
        matching: find.byType(Text),
      ),
    );
    expect(switchText.style?.decoration, TextDecoration.underline);
    expect(
      tester.widget<TextButton>(
        find.byKey(const Key('maker_settings_switch_appreciator')),
      ).style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.darkGray,
    );

    expect(find.byKey(const Key('maker_settings_save_close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('maker_settings_save_close')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.lastDraft?.locationId, 3);
    expect(repository.lastDraft?.showEmail, isTrue);
    expect(repository.closeCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maker settings has no overflow on 320x520 viewport', (
    WidgetTester tester,
  ) async {
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
            onSwitchedToAppreciator: _noopDestination,
          ),
        ),
      ),
    );

    await _finishInitialLoad(tester);

    expect(find.text('Maker Info Setting'), findsOneWidget);
    expect(find.byKey(const Key('maker_settings_save_close')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final settingsList = find.byKey(const Key('maker_settings_scroll'));
    expect(settingsList, findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const Key('maker_settings_carousel_4')),
      settingsList,
      const Offset(0, -300),
    );

    expect(find.byKey(const Key('maker_settings_carousel_4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Switch to Appreciator preserves session and emits resolved destination',
    (WidgetTester tester) async {
      final repository = _FakeSettingsRepository();
      final switchRepository = _FakeExperienceSwitchRepository(
        MakerEntryDestination.appreciatorDiscovery,
      );
      MakerEntryDestination? switchedTo;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
            experienceSwitchRepositoryProvider.overrideWithValue(
              switchRepository,
            ),
          ],
          child: MaterialApp(
            home: MakerInfoSettingsScreen(
              onClose: _noop,
              onSwitchedToAppreciator: (destination) {
                switchedTo = destination;
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

      expect(repository.logoutCalls, 0);
      expect(switchRepository.appreciatorCalls, 1);
      expect(switchedTo, MakerEntryDestination.appreciatorDiscovery);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Content 2 update is confirmed from backend before settings closes',
    (WidgetTester tester) async {
      final repository = _FakeSettingsRepository()..confirmedSlots.add(2);

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
              onSwitchedToAppreciator: _noopDestination,
            ),
          ),
        ),
      );

      await _finishInitialLoad(tester);

      final settingsList = find.byKey(const Key('maker_settings_scroll'));
      final title = find.byKey(const Key('maker_settings_artwork_title_2'));
      await _scrollIntoSafeTapRegion(
        tester,
        target: title,
        scrollView: settingsList,
      );

      await tester.enterText(title, 'Updated Content Two');
      await tester.pump();

      await tester.tap(find.byKey(const Key('maker_settings_save_close')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.saveArtworkCalls, 1);
      expect(repository.loadCalls, 2);
      expect(repository.closeCalls, 1);
      expect(repository.confirmedSlots.contains(2), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('uploaded artwork has a purple 16px delete icon inside its box', (
    WidgetTester tester,
  ) async {
    final repository = _FakeSettingsRepository()..confirmedSlots.add(2);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          makerInfoSettingsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: MakerInfoSettingsScreen(
            onClose: _noop,
            onSwitchedToAppreciator: _noopDestination,
          ),
        ),
      ),
    );
    await _finishInitialLoad(tester);

    final list = find.byKey(const Key('maker_settings_scroll'));
    final mediaBox = find.byKey(const Key('maker_settings_carousel_pick_2'));
    await _scrollIntoSafeTapRegion(tester, target: mediaBox, scrollView: list);

    final remove = find.byKey(const Key('maker_settings_carousel_remove_2'));
    expect(remove, findsOneWidget);
    final iconButton = tester.widget<IconButton>(remove);
    expect(iconButton.iconSize, 16);
    expect(iconButton.color, AppColors.primary);
    final icon = iconButton.icon as Icon;
    expect(icon.size, 16);
    final boxRect = tester.getRect(mediaBox);
    final removeRect = tester.getRect(remove);
    expect(removeRect.top, boxRect.top);
    expect(removeRect.right, boxRect.right);
    expect(tester.takeException(), isNull);
  });

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
              onSwitchedToAppreciator: _noopDestination,
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

      await tester.tap(find.byKey(const Key('maker_settings_save_close')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 1);
      expect(repository.saveCarouselCalls, 0);
      expect(repository.deleteCarouselCalls, 0);
      expect(repository.saveArtworkCalls, 0);
      expect(repository.deleteArtworkCalls, 0);
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
  await tester.dragUntilVisible(target, scrollView, const Offset(0, -240));
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

void _noopDestination(MakerEntryDestination destination) {}

class _FakeSettingsRepository implements MakerInfoSettingsRepositoryContract {
  int saveCalls = 0;
  int closeCalls = 0;
  int loadCalls = 0;
  int logoutCalls = 0;
  int saveCarouselCalls = 0;
  int deleteCarouselCalls = 0;
  int saveArtworkCalls = 0;
  int deleteArtworkCalls = 0;
  MakerInfoSettingsDraft? lastDraft;
  final Set<int> confirmedSlots = <int>{};

  @override
  Future<MakerInfoSettingsData> load() async {
    loadCalls++;
    return MakerInfoSettingsData(
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
      artworkSlots: confirmedSlots
          .map(
            (slot) => MakerInfoArtworkSlot(
              slot: slot,
              artwork: MakerSettingsArtwork(
                id: 100 + slot,
                title: slot == 2 ? 'Content Two' : 'Artwork $slot',
                description: '',
                typeId: 1,
                styleId: 2,
                locationId: 3,
                locationText: 'Chicago, IL',
                moderationStatus: 'pending',
                isVisible: true,
                media: <MakerSettingsArtworkMedia>[
                  MakerSettingsArtworkMedia(
                    id: 200 + slot,
                    url: 'https://example.test/content$slot.jpg',
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      savedCount: 37,
      availableTypes: <MakerSettingsTaxonomyOption>[
        MakerSettingsTaxonomyOption(id: 1, name: 'Painting', slug: 'painting'),
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

    return MakerCarouselItem(slot: slot, kind: 'image', caption: caption);
  }

  @override
  Future<void> deleteCarouselSlot(int slot) async {
    deleteCarouselCalls++;
  }

  @override
  Future<void> deleteProfileImage() async {
    deleteCarouselCalls++;
  }

  @override
  Future<MakerInfoArtworkSlot> saveArtworkSlot({
    required int slot,
    required MakerSettingsArtwork? existingArtwork,
    required String title,
    required String description,
    required int? typeId,
    required int? styleId,
    required int? locationId,
    required String locationText,
    Uint8List? bytes,
    String? fileName,
  }) async {
    saveArtworkCalls++;
    confirmedSlots.add(slot);
    return MakerInfoArtworkSlot(
      slot: slot,
      artwork: MakerSettingsArtwork(
        id: existingArtwork?.id ?? 100 + slot,
        title: title,
        description: description,
        typeId: typeId,
        styleId: styleId,
        locationId: locationId,
        locationText: locationText,
        moderationStatus: 'pending',
        isVisible: true,
        media: const <MakerSettingsArtworkMedia>[],
      ),
    );
  }

  @override
  Future<void> deleteArtworkSlot(int slot) async {
    deleteArtworkCalls++;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _FakeExperienceSwitchRepository
    implements ExperienceSwitchRepositoryContract {
  _FakeExperienceSwitchRepository(this.destination);

  final MakerEntryDestination destination;
  int appreciatorCalls = 0;

  @override
  Future<MakerEntryDestination> switchToAppreciator() async {
    appreciatorCalls++;
    return destination;
  }

  @override
  Future<MakerEntryDestination> switchToMaker() async =>
      MakerEntryDestination.discovery;
}
