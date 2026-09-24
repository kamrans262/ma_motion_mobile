import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/features/auth/presentation/screens/ma_email_login_screen.dart';

void main() {
  testWidgets('Login uses updated copy and purple Create Account button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MaEmailLoginScreen(
            onCreateAccount: () {},
            onAuthenticated: (_) {},
          ),
        ),
      ),
    );

    final heading = tester.widget<Text>(
      find.byKey(const Key('email_login_heading')),
    );
    expect(heading.data, 'Welcome to the space between.');
    expect(heading.style?.fontFamily, 'HelveticaNeueLTStd');
    expect(heading.style?.fontSize, 34);
    expect(heading.style?.fontWeight, FontWeight.w500);
    expect(heading.style?.letterSpacing, -0.5);
    expect(heading.style?.height, 1.22);

    final email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('email_login_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(email.decoration?.hintText, 'you@email.com');
    expect(
      email.decoration?.contentPadding,
      const EdgeInsets.fromLTRB(20, 16, 20, 12),
    );

    final create = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('email_create_account_button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(
      create.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );

    final terms = tester.widget<Text>(
      find.byKey(const Key('email_login_terms_text')),
    );
    final privacy = tester.widget<Text>(
      find.byKey(const Key('email_login_privacy_text')),
    );
    expect(terms.style?.color, AppColors.primary);
    expect(privacy.style?.color, AppColors.primary);
    expect(terms.style?.decoration, TextDecoration.underline);
    expect(privacy.style?.decoration, TextDecoration.underline);
    expect(terms.style?.decorationColor, AppColors.primary);
    expect(privacy.style?.decorationColor, AppColors.primary);
    expect(
      tester.getTopLeft(find.byKey(const Key('email_login_privacy_text'))).dy,
      closeTo(
        tester.getTopLeft(find.byKey(const Key('email_login_terms_text'))).dy,
        1,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
