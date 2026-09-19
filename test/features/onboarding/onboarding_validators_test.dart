import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/domain/onboarding_validators.dart';

void main() {
  group('shared onboarding validation', () {
    test('validates names and locations with minimum and maximum limits', () {
      expect(OnboardingValidators.makerName('   '), isNotNull);
      expect(
        OnboardingValidators.makerName('A'),
        contains('at least 2 characters'),
      );
      expect(
        OnboardingValidators.appreciatorName('A'),
        contains('at least 2 characters'),
      );
      expect(
        OnboardingValidators.location('A'),
        contains('at least 2 characters'),
      );
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

    test('Maker artist statement is optional with a 5000-character maximum', () {
      expect(OnboardingValidators.aboutWork(''), isNull);
      expect(OnboardingValidators.aboutWork('Short'), isNull);
      expect(
        OnboardingValidators.aboutWork('Original mixed-media artwork'),
        isNull,
      );
      expect(
        OnboardingValidators.aboutWork('A'.padLeft(5001, 'A')),
        contains('5000 characters'),
      );
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
      expect(
        OnboardingValidators.makerStyles(<String>{'Contemporary'}),
        isNull,
      );

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
