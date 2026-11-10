# MA Motion — Firebase push setup

The Flutter app now includes Firebase Cloud Messaging integration. The existing Firebase project named **Ma motion** must be linked to the native apps before actual delivery can work. The Firebase display name is not the Firebase project ID.

## Mobile configuration

Android package ID: com.mamotion.ma_motion_mobile
iOS bundle ID: com.mamotion.maMotionMobile

On your Mac in the MA Motion Flutter repository:

1. Install and sign in to Firebase CLI using: firebase login
2. Install FlutterFire CLI using: dart pub global activate flutterfire_cli
3. Run: flutterfire configure --platforms=android,ios
4. Select the **Ma motion** Firebase project and register the existing Android and iOS bundle IDs.
5. Run: flutter pub get
6. Run: flutter run

The Android build will automatically use Firebase when the generated android/app/google-services.json exists. Without native configuration, push stays unavailable but the app continues launching. The generated native platform configuration files are excluded from Git to prevent environment mix-ups.

For iOS, open ios/Runner.xcworkspace in Xcode, ensure Push Notifications and Background Modes / Remote notifications capabilities are enabled, confirm signing and APNs entitlement for the chosen build, and upload an APNs authentication key in Firebase Project settings > Cloud Messaging. A physical iPhone is required for a complete APNs delivery test.

## Backend / Hostinger

1. Pull latest ma_motion_backend main.
2. Run: php artisan migrate --force
3. In Firebase Project settings > Service accounts, generate a private service account JSON and upload it to a private server directory **outside the public website root**. Never commit this JSON or place it under public_html.
4. Set in Laravel .env:
   MA_FCM_ENABLED=true
   MA_FCM_PROJECT_ID=<actual-firebase-project-id>
   MA_FCM_CREDENTIALS_PATH=/absolute/private/path/service-account.json
5. Run: php artisan optimize:clear

The Laravel server uses the private service account to authorize Firebase HTTP v1 delivery. Notification delivery is dispatched after the HTTP response (no persistent Redis worker needed on shared hosting). The existing database notification is kept even if Firebase delivery fails.

## Behavior

When an active Maker announces a visible current/upcoming show, active Appreciators who have saved that Maker and enabled saved-Maker show alerts get one database alert per show. FCM pushes go to each registered Android/iOS device. Foreground Android uses an MA Motion notification channel; iOS foreground uses native presentation. Tapping a push opens the notification inbox where users can read alerts and switch show alerts on/off. Only newly created notification records trigger a push, preventing duplicate alerts from show edits.

## Verify on real devices

- Sign in through email OTP; allow system notification permission and confirm the push_device_tokens database row.
- Save a Maker as an Appreciator, then create a current/upcoming show for that Maker.
- Test with the app open, in background, and completely closed.
- Tap the push to open the notification inbox; test the saved-Maker preference.
- Log out and confirm token removal.
- Repeat on real iOS hardware after APNs is configured.

Official Firebase setup: https://firebase.google.com/docs/flutter/setup
Official FCM Flutter setup: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
