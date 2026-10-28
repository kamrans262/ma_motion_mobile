import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/storage/auth_token_store.dart';

/// The OS presents notification payloads in the background. Never make
/// authenticated API calls from a background isolate.
@pragma('vm:entry-point')
Future<void> maFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Handles FCM foreground/background/open, safe token rotation, and
/// per-session registration without changing the existing MA layouts.
class MaPushNotifications {
  MaPushNotifications._();

  static final MaPushNotifications instance = MaPushNotifications._();

  static const String channelId = 'ma_motion_show_alerts';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final ValueNotifier<int> inboxChanges = ValueNotifier<int>(0);
  ApiGateway? _api;
  AuthTokenStore? _tokens;
  StreamSubscription<bool>? _sessionChanges;
  StreamSubscription<String>? _fcmTokenChanges;
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  VoidCallback? _onOpenInbox;

  bool firebaseReady = false;
  bool _pendingOpen = false;
  String? _registeredToken;
  bool _registering = false;

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      // The Firebase project is configured using FlutterFire CLI on the
      // developer's machine; do not hardcode project IDs or credentials.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(maFirebaseBackgroundHandler);
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (_) => _openInbox(),
      );

      if (Platform.isAndroid) {
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                channelId,
                'Maker show alerts',
                description: 'Updates when saved Makers announce shows.',
                importance: Importance.high,
              ),
            );
      }

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _foregroundMessages = FirebaseMessaging.onMessage.listen((message) {
        inboxChanges.value++;
        final alert = message.notification;
        if (Platform.isAndroid && alert != null) {
          unawaited(_local.show(
            id: message.messageId.hashCode,
            title: alert.title,
            body: alert.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                channelId,
                'Maker show alerts',
                channelDescription: 'Updates when saved Makers announce shows.',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: message.data['notification_id']?.toString(),
          ));
        }
      });
      _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _openInbox(),
      );
      if (await FirebaseMessaging.instance.getInitialMessage() != null) {
        _pendingOpen = true;
      }
      firebaseReady = true;
    } catch (error) {
      // The app must still open before the Firebase platform files are added.
      debugPrint('MA Motion push is awaiting Firebase platform setup: $error');
    }
  }

  void bind({
    required ApiGateway api,
    required AuthTokenStore tokens,
    required VoidCallback onOpenInbox,
  }) {
    _api = api;
    _tokens = tokens;
    _onOpenInbox = onOpenInbox;
    _sessionChanges ??= authSessionChanges.stream.listen((signedIn) {
      if (signedIn) {
        unawaited(syncToken());
      } else {
        _registeredToken = null;
      }
    });
    if (firebaseReady) {
      _fcmTokenChanges ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => unawaited(syncToken(force: true)),
      );
    }
    if (_pendingOpen) {
      _pendingOpen = false;
      // Defer until the MaterialApp has mounted its router.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInbox());
    }
    unawaited(syncToken());
  }

  Future<void> syncToken({bool force = false}) async {
    if (!firebaseReady || _registering || _api == null || _tokens == null) return;
    _registering = true;
    try {
      final session = await _tokens!.read();
      if (session == null || session.trim().isEmpty) return;
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;

      // On Apple, APNs must be available before asking FCM for its token.
      if (Platform.isIOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      if (!force && _registeredToken == token) return;

      await _api!.post(ApiPaths.pushTokens, data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      _registeredToken = token;
    } catch (error) {
      debugPrint('MA Motion could not register push token: $error');
    } finally {
      _registering = false;
    }
  }

  /// Called before deliberate logout. The server also cascade-deletes tokens
  /// when the account itself is deleted.
  Future<void> unregister() async {
    if (!firebaseReady || _api == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _api!.delete(ApiPaths.pushTokens, data: {'token': token});
      }
    } catch (error) {
      debugPrint('MA Motion push token removal could not be confirmed: $error');
    } finally {
      _registeredToken = null;
    }
  }

  void _openInbox() {
    final callback = _onOpenInbox;
    if (callback == null) {
      _pendingOpen = true;
    } else {
      callback();
    }
  }

  void dispose() {
    _sessionChanges?.cancel();
    _sessionChanges = null;
    _fcmTokenChanges?.cancel();
    _fcmTokenChanges = null;
    _foregroundMessages?.cancel();
    _foregroundMessages = null;
    _openedMessages?.cancel();
    _openedMessages = null;
    _onOpenInbox = null;
  }
}
