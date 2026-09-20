import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/settings/data/appreciator_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/appreciator_settings_models.dart';
import 'package:ma_motion_mobile/features/settings/presentation/widgets/appreciator_settings_modal.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('modal overlays and blurs current grid context', (tester) async {
    final repository = _FakeAppreciatorSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appreciatorSettingsRepositoryProvider.overrideWithValue(repository),
          experienceSwitchRepositoryProvider.overrideWithValue(
            _FakeExperienceSwitchRepository(),
          ),
        ],
        child: const MaterialApp(home: _ModalHarness()),
      ),
    );

    await tester.tap(find.byKey(const Key('open_appreciator_settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('discovery_grid_context')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const Key('appreciator_settings_card')), findsOneWidget);
    final card = tester.widget<Material>(
      find.byKey(const Key('appreciator_settings_card')),
    );
    expect(card.color, AppColors.artworkBackground);
    final save = tester.widget<OutlinedButton>(
      find.byKey(const Key('appreciator_settings_save_close')),
    );
    expect(
      save.style?.backgroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF020202),
    );
    expect(
      save.style?.backgroundColor?.resolve(<WidgetState>{
        WidgetState.pressed,
      }),
      AppColors.primary,
    );
    expect(save.style?.side?.resolve(<WidgetState>{})?.width, 1);
    expect(
      tester.getSize(
        find.byKey(const Key('appreciator_settings_save_close')),
      ).height,
      48,
    );
    expect(tester.widget<Text>(find.text('Save & Close')).style?.fontSize, 16);
    expect(find.text('Settings'), findsOneWidget);

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('appreciator_settings_name')))
          .controller
          ?.text,
      'Ari Viewer',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Save and Close persists edits before dismissing modal', (
    tester,
  ) async {
    final repository = _FakeAppreciatorSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appreciatorSettingsRepositoryProvider.overrideWithValue(repository),
          experienceSwitchRepositoryProvider.overrideWithValue(
            _FakeExperienceSwitchRepository(),
          ),
        ],
        child: const MaterialApp(home: _ModalHarness()),
      ),
    );

    await tester.tap(find.byKey(const Key('open_appreciator_settings')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('appreciator_settings_name')),
      'Ari Updated',
    );
    await tester.enterText(
      find.byKey(const Key('appreciator_settings_location')),
      'Brooklyn, NY',
    );
    await tester.enterText(
      find.byKey(const Key('appreciator_settings_email')),
      'ari.updated@example.com',
    );

    await tester.ensureVisible(
      find.byKey(const Key('appreciator_settings_save_close')),
    );
    await tester.tap(
      find.byKey(const Key('appreciator_settings_save_close')).hitTestable(),
    );
    await tester.pump();

    expect(repository.savedDraft?.name, 'Ari Updated');
    expect(repository.savedDraft?.locationText, 'Brooklyn, NY');
    expect(repository.savedDraft?.locationId, 12);
    expect(repository.savedDraft?.email, 'ari.updated@example.com');
    expect(
      find.byKey(const Key('appreciator_settings_success')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appreciator_settings_card')), findsNothing);
    expect(find.byKey(const Key('discovery_grid_context')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Switch to Maker saves then uses same-account switch flow', (
    tester,
  ) async {
    final repository = _FakeAppreciatorSettingsRepository();
    final switchRepository = _FakeExperienceSwitchRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appreciatorSettingsRepositoryProvider.overrideWithValue(repository),
          experienceSwitchRepositoryProvider.overrideWithValue(
            switchRepository,
          ),
        ],
        child: const MaterialApp(home: _ModalHarness()),
      ),
    );

    await tester.tap(find.byKey(const Key('open_appreciator_settings')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('appreciator_settings_switch_to_maker')),
    );
    await tester.tap(
      find
          .byKey(const Key('appreciator_settings_switch_to_maker'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(switchRepository.switchToMakerCount, 1);
    expect(find.byKey(const Key('appreciator_settings_card')), findsNothing);
    expect(find.text('maker destination: profileSetup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modal remains scroll-safe on compact viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appreciatorSettingsRepositoryProvider.overrideWithValue(
            _FakeAppreciatorSettingsRepository(),
          ),
          experienceSwitchRepositoryProvider.overrideWithValue(
            _FakeExperienceSwitchRepository(),
          ),
        ],
        child: const MaterialApp(home: _ModalHarness()),
      ),
    );

    await tester.tap(find.byKey(const Key('open_appreciator_settings')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('appreciator_settings_scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appreciator_settings_save_close')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _ModalHarness extends StatefulWidget {
  const _ModalHarness();

  @override
  State<_ModalHarness> createState() => _ModalHarnessState();
}

class _ModalHarnessState extends State<_ModalHarness> {
  MakerEntryDestination? destination;

  Future<void> _open() async {
    final result = await showAppreciatorSettingsModal(context);

    if (!mounted || result == null) return;
    setState(() {
      destination = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SizedBox.expand(
            key: Key('discovery_grid_context'),
            child: ColoredBox(color: Color(0xFF102019)),
          ),
          Center(
            child: ElevatedButton(
              key: const Key('open_appreciator_settings'),
              onPressed: _open,
              child: const Text('Open settings'),
            ),
          ),
          if (destination != null)
            Align(
              alignment: Alignment.topCenter,
              child: Text('maker destination: ${destination!.name}'),
            ),
        ],
      ),
    );
  }
}

class _FakeAppreciatorSettingsRepository
    implements AppreciatorSettingsRepositoryContract {
  AppreciatorSettingsDraft? savedDraft;
  int saveCount = 0;

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
  Future<int?> resolveLocationId(String query) async {
    return query.trim() == 'Brooklyn, NY' ? 12 : null;
  }

  @override
  Future<AppreciatorSettingsData> save(AppreciatorSettingsDraft draft) async {
    savedDraft = draft;
    saveCount++;

    return AppreciatorSettingsData(
      name: draft.name.trim(),
      email: draft.email.trim(),
      locationText: draft.locationText.trim(),
      locationId: draft.locationId,
      onboardingCompleted: true,
    );
  }
}

class _FakeExperienceSwitchRepository
    implements ExperienceSwitchRepositoryContract {
  int switchToMakerCount = 0;

  @override
  Future<MakerEntryDestination> switchToAppreciator() async {
    return MakerEntryDestination.appreciatorDiscovery;
  }

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    switchToMakerCount++;
    return MakerEntryDestination.profileSetup;
  }
}
