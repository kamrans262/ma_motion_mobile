import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/auth/data/maker_entry_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/auth/presentation/screens/maker_auth_screen.dart';

void main() {
  testWidgets('Maker sign-in submits and returns discovery destination', (
    tester,
  ) async {
    final repository = _FakeMakerEntryRepository();
    MakerEntryDestination? destination;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [makerEntryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MakerAuthScreen(
            onBack: () {},
            onAuthenticated: (value) {
              destination = value;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('maker_auth_email')),
      'maker@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('maker_auth_password')),
      'MakerPass1',
    );
    await tester.tap(find.byKey(const Key('maker_auth_submit_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.loginCalls, 1);
    expect(destination, MakerEntryDestination.discovery);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maker create-account mode sends registration fields', (
    tester,
  ) async {
    final repository = _FakeMakerEntryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [makerEntryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MakerAuthScreen(onBack: () {}, onAuthenticated: (_) {}),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('maker_auth_create_mode')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('maker_auth_name')),
      'MA Studio',
    );
    await tester.enterText(
      find.byKey(const Key('maker_auth_email')),
      'maker@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('maker_auth_password')),
      'MakerPass1',
    );
    await tester.enterText(
      find.byKey(const Key('maker_auth_password_confirmation')),
      'MakerPass1',
    );

    await tester.tap(find.byKey(const Key('maker_auth_submit_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.registerCalls, 1);
    expect(repository.lastName, 'MA Studio');
    expect(tester.takeException(), isNull);
  });
}

class _FakeMakerEntryRepository implements MakerEntryRepositoryContract {
  int loginCalls = 0;
  int registerCalls = 0;
  String? lastName;

  @override
  Future<MakerEntryDestination> restoreAppEntry() async {
    return MakerEntryDestination.join;
  }

  @override
  Future<MakerEntryDestination> loginMaker({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return MakerEntryDestination.discovery;
  }

  @override
  Future<MakerEntryDestination> registerMaker({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    registerCalls++;
    lastName = name;
    return MakerEntryDestination.profileSetup;
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    return 'Password reset sent.';
  }
}
