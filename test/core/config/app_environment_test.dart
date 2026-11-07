import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/config/app_environment.dart';

void main() {
  test('default API uses the MA Motion production domain', () {
    expect(
      AppEnvironment.apiBaseUrl,
      'https://app.ma-spaceforart.com/api/v1',
    );
    expect(AppEnvironment.connectTimeout.inSeconds, greaterThan(0));
    expect(AppEnvironment.receiveTimeout.inSeconds, greaterThan(0));
  });
}
