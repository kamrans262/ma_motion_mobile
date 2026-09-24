import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/auth/data/email_otp_repository.dart';
import 'package:ma_motion_mobile/features/auth/presentation/screens/ma_email_otp_screen.dart';

void main() {
  testWidgets('all six OTP fields have four extra pixels of top padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MaEmailOtpScreen(
            challenge: const EmailOtpChallenge(
              id: 'test-challenge',
              email: 'you@email.com',
              purpose: EmailOtpPurpose.login,
              requiresAuth: false,
              expiresInSeconds: 600,
              resendAfterSeconds: 0,
            ),
            onVerified: (_, _) {},
            onBack: () {},
          ),
        ),
      ),
    );

    for (var index = 0; index < 6; index++) {
      final key = index == 0
          ? const Key('email_otp_code_field')
          : Key('email_otp_code_field_$index');
      final input = tester.widget<TextField>(find.byKey(key));
      expect(
        input.decoration?.contentPadding,
        const EdgeInsets.fromLTRB(0, 18, 0, 14),
      );
    }

    expect(tester.takeException(), isNull);
  });
}
