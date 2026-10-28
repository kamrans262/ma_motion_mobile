import 'dart:async';

// Login, email-OTP, logout and 401 handling share one session-change signal.
final authSessionChanges = StreamController<bool>.broadcast(sync: true);

abstract interface class AuthTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}
