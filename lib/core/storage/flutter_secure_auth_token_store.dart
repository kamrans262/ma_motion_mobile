import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_token_store.dart';

class FlutterSecureAuthTokenStore implements AuthTokenStore {
  FlutterSecureAuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'ma_motion_api_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) async {
    final trimmed = token.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty.');
    }

    await _storage.write(key: _tokenKey, value: trimmed);
  }

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
