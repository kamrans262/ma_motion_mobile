import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/auth/domain/current_user.dart';

void main() {
  test('Maker account exposes Maker profile only', () {
    final user = CurrentUser.fromMap(<String, dynamic>{
      'id': 19,
      'name': 'Studio Maker',
      'email': 'maker@example.com',
      'role': 'maker',
      'maker_registered': true,
      'maker_onboarding_completed': true,
      'appreciator_registered': false,
      'appreciator_onboarding_completed': false,
      'maker_profile': <String, dynamic>{
        'location_text': 'Brooklyn 11201',
        'bio': 'My existing statement',
        'profile_image_url': 'https://example.test/image.jpg',
      },
      'appreciator_profile': null,
    });

    expect(user.id, 19);
    expect(user.isMaker, isTrue);
    expect(user.isAppreciator, isFalse);
    expect(user.makerOnboardingCompleted, isTrue);
    expect(user.appreciatorOnboardingCompleted, isFalse);
    expect(user.makerLocation, 'Brooklyn 11201');
    expect(user.appreciatorLocation, isEmpty);
    expect(user.makerBio, 'My existing statement');
  });

  test('Appreciator account exposes Appreciator profile only', () {
    final user = CurrentUser.fromMap(<String, dynamic>{
      'id': 20,
      'name': 'Art Lover',
      'email': 'lover@example.com',
      'role': 'appreciator',
      'maker_registered': false,
      'maker_onboarding_completed': false,
      'appreciator_registered': true,
      'appreciator_onboarding_completed': true,
      'maker_profile': null,
      'appreciator_profile': <String, dynamic>{
        'location_text': 'Chicago 60601',
        'location_id': 3,
      },
    });

    expect(user.isMaker, isFalse);
    expect(user.isAppreciator, isTrue);
    expect(user.makerOnboardingCompleted, isFalse);
    expect(user.appreciatorOnboardingCompleted, isTrue);
    expect(user.makerLocation, isEmpty);
    expect(user.appreciatorLocation, 'Chicago 60601');
  });
}
