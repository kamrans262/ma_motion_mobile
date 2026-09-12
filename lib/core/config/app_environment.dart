import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'MA_API_BASE_URL',
    defaultValue: '',
  );

  static const String _connectTimeoutSeconds = String.fromEnvironment(
    'MA_API_CONNECT_TIMEOUT_SECONDS',
    defaultValue: '20',
  );

  static const String _receiveTimeoutSeconds = String.fromEnvironment(
    'MA_API_RECEIVE_TIMEOUT_SECONDS',
    defaultValue: '30',
  );

  static bool get hasConfiguredApiBaseUrl => _rawApiBaseUrl.trim().isNotEmpty;

  static String get apiBaseUrl {
    final raw = _rawApiBaseUrl.trim();

    if (raw.isEmpty) {
      if (!kReleaseMode) {
        // Android USB development uses adb reverse so device localhost:8000
        // reaches the Laravel server running on the development PC.
        return 'http://127.0.0.1:8000/api/v1';
      }

      return 'https://api.invalid.ma-motion.local/api/v1';
    }

    var normalized = raw;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    if (normalized.endsWith('/api/v1')) {
      return normalized;
    }

    return '$normalized/api/v1';
  }

  static Duration get connectTimeout =>
      Duration(seconds: int.tryParse(_connectTimeoutSeconds) ?? 20);

  static Duration get receiveTimeout =>
      Duration(seconds: int.tryParse(_receiveTimeoutSeconds) ?? 30);
}
