import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/config/app_environment.dart';

void main() {
  test('default API uses the deployed Hostinger Laravel endpoint', () {
    expect(
      AppEnvironment.apiBaseUrl,
      'https://slategray-fly-111965.hostingersite.com/api/v1',
    );
    expect(AppEnvironment.connectTimeout.inSeconds, greaterThan(0));
    expect(AppEnvironment.receiveTimeout.inSeconds, greaterThan(0));
  });
}
