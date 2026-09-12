import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/config/app_environment.dart';

void main() {
  test(
    'unconfigured debug API uses the local Laravel development endpoint',
    () {
      expect(AppEnvironment.apiBaseUrl, 'http://127.0.0.1:8001/api/v1');
      expect(AppEnvironment.connectTimeout.inSeconds, greaterThan(0));
      expect(AppEnvironment.receiveTimeout.inSeconds, greaterThan(0));
    },
  );
}
