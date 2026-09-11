import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/config/app_environment.dart';

void main() {
  test('unconfigured API uses an intentionally invalid safe fallback', () {
    expect(AppEnvironment.apiBaseUrl, contains('/api/v1'));
    expect(AppEnvironment.connectTimeout.inSeconds, greaterThan(0));
    expect(AppEnvironment.receiveTimeout.inSeconds, greaterThan(0));
  });
}
