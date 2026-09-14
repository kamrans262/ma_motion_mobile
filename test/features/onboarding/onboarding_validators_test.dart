import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/domain/onboarding_validators.dart';

void main() {
  group('shared onboarding validation', () {
    test('validates names and locations with contract limits', () {
      expect(OnboardingValidators.makerName('   '), isNotNull);
      expect(
        OnboardingValidators.makerName('A'.padLeft(121, 'A')),
        contains('120 characters'),
      );
      expect(OnboardingValidators.makerName('MA Studio'), isNull);

      expect(OnboardingValidators.appreciatorName('   '), isNotNull);
      expect(
        OnboardingValidators.location('L'.padLeft(181, 'L')),
        contains('180 characters'),
      );
      expect(OnboardingValidators.location('New York, NY'), isNull);
    });

    test('validates email and optional website formats', () {
      expect(OnboardingValidators.email('invalid'), isNotNull);
      expect(OnboardingValidators.email('artist@example.com'), isNull);
      expect(OnboardingValidators.website(''), isNull);
      expect(OnboardingValidators.website('not a website'), isNotNull);
      expect(OnboardingValidators.website('artist.com'), isNull);
      expect(OnboardingValidators.website('https://artist.com'), isNull);
    });

    test('validates Maker taxonomy and salon image requirements', () {
      expect(OnboardingValidators.makerTypes(<String>{}), isNotNull);
      expect(OnboardingValidators.makerStyles(<String>{}), isNotNull);
      expect(OnboardingValidators.makerTypes(<String>{'Painting'}), isNull);
      expect(OnboardingValidators.makerStyles(<String>{'Contemporary'}), isNull);

      expect(
        OnboardingValidators.salonImage(bytes: null, fileName: null),
        isNotNull,
      );
      expect(
        OnboardingValidators.salonImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'salon.heic',
        ),
        contains('JPG, PNG, or WebP'),
      );
      expect(
        OnboardingValidators.salonImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileName: 'salon.png',
        ),
        isNull,
      );
    });
  });
}
