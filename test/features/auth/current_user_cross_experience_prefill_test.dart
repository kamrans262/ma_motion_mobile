import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/auth/domain/current_user.dart';

void main() {
  test(
    'both completed profiles expose independent persistent shared fields',
    () {
      final user = CurrentUser.fromMap(<String, dynamic>{
        'id': 19,
        'name': 'Art Lover',
        'email': 'lover@example.com',
        'role': 'maker',
        'active_experience': 'maker',
        'maker_registered': true,
        'maker_onboarding_completed': true,
        'appreciator_registered': true,
        'appreciator_onboarding_completed': true,
        'maker_profile': <String, dynamic>{
          'location_text': 'Brooklyn 11201',
          'bio': 'My existing statement',
          'profile_image_url': 'https://example.test/image.jpg',
        },
        'appreciator_profile': <String, dynamic>{
          'location_text': 'Chicago 60601',
          'location_id': 3,
        },
      });

      expect(user.id, 19);
      expect(user.isMaker, isTrue);
      expect(user.makerOnboardingCompleted, isTrue);
      expect(user.appreciatorOnboardingCompleted, isTrue);
      expect(user.makerLocation, 'Brooklyn 11201');
      expect(user.appreciatorLocation, 'Chicago 60601');
      expect(user.makerBio, 'My existing statement');
      expect(user.email, 'lover@example.com');
    },
  );

  test('a newly created second profile never replaces the source location', () {
    final user = CurrentUser.fromMap(<String, dynamic>{
      'id': 19,
      'name': 'Art Lover',
      'email': 'lover@example.com',
      'role': 'maker',
      'maker_registered': true,
      'maker_onboarding_completed': false,
      'appreciator_registered': true,
      'appreciator_onboarding_completed': true,
      'maker_profile': <String, dynamic>{'location_text': null},
      'appreciator_profile': <String, dynamic>{
        'location_text': 'Chicago 60601',
      },
    });

    expect(user.makerLocation, isEmpty);
    expect(user.appreciatorLocation, 'Chicago 60601');
    expect(user.makerOnboardingCompleted, isFalse);
  });
}
