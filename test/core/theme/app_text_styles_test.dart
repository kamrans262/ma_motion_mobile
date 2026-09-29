import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('display and body font assets use the shared typography tokens', () async {
    final displayFont = await rootBundle.load(
      'assets/fonts/HelveticaNeueLTStd-Md.otf',
    );
    final bodyFont = await rootBundle.load('assets/fonts/InstrumentSans.ttf');
    expect(displayFont.lengthInBytes, 28260);
    expect(bodyFont.lengthInBytes, 194336);

    expect(AppTextStyles.displayFontFamily, 'HelveticaNeueLTStd');
    expect(AppTextStyles.bodyFontFamily, 'Instrument Sans');
    expect(AppTextStyles.fontFamily, AppTextStyles.bodyFontFamily);

    expect(AppTextStyles.onboardingHeading.height, 1.22);
    expect(AppTextStyles.onboardingHeading.letterSpacing, -0.8);
    expect(AppTextStyles.onboardingHeading.fontSize, 34);
    expect(
      AppTextStyles.onboardingHeading.fontFamily,
      AppTextStyles.displayFontFamily,
    );
    expect(
      AppTextStyles.onboardingHelper.fontFamily,
      AppTextStyles.bodyFontFamily,
    );
    expect(AppTextStyles.onboardingHelper.height, 1.4);
    expect(AppTextStyles.onboardingHelper.letterSpacing, 0.2);
    expect(AppTextStyles.field.fontFamily, AppTextStyles.bodyFontFamily);
    expect(AppTextStyles.field.height, 1.0);
    expect(AppTextStyles.field.letterSpacing, 0.2);
    expect(AppTextStyles.fieldHint.fontFamily, AppTextStyles.bodyFontFamily);
    expect(AppTextStyles.fieldHint.height, 1.0);
    expect(AppTextStyles.fieldHint.letterSpacing, 0.2);
    expect(AppTextStyles.buttonDark.fontFamily, AppTextStyles.bodyFontFamily);
    expect(AppTextStyles.buttonDark.height, 1.0);
    expect(
      AppTextStyles.buttonPurple.fontFamily,
      AppTextStyles.bodyFontFamily,
    );
    expect(AppTextStyles.buttonPurple.letterSpacing, 0.2);
    expect(AppTextStyles.chip.fontFamily, AppTextStyles.bodyFontFamily);
    expect(AppTextStyles.chip.height, 1.25);
    expect(AppTextStyles.error.fontFamily, AppTextStyles.bodyFontFamily);
    expect(AppTextStyles.error.height, 1.3);
  });
}
