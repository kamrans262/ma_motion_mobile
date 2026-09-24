import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the supplied Helvetica file is bundled with updated typography',
    () async {
      final font = await rootBundle.load(
        'assets/fonts/HelveticaNeueLTStd-Md.otf',
      );
      expect(font.lengthInBytes, 28260);

      expect(AppTextStyles.onboardingHeading.height, 1.22);
      expect(AppTextStyles.onboardingHeading.letterSpacing, -0.5);
      expect(AppTextStyles.onboardingHeading.fontSize, 34);
      expect(AppTextStyles.onboardingHeading.fontFamily, 'HelveticaNeueLTStd');
      expect(AppTextStyles.onboardingHelper.height, 1.4);
      expect(AppTextStyles.onboardingHelper.letterSpacing, 0.2);
      expect(AppTextStyles.field.height, 1.25);
      expect(AppTextStyles.field.letterSpacing, 0.2);
      expect(AppTextStyles.fieldHint.height, 1.25);
      expect(AppTextStyles.fieldHint.letterSpacing, 0.2);
      expect(AppTextStyles.buttonDark.height, 1.2);
      expect(AppTextStyles.buttonPurple.letterSpacing, 0.2);
      expect(AppTextStyles.chip.height, 1.25);
      expect(AppTextStyles.error.height, 1.3);
    },
  );
}
