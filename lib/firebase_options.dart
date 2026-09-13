import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase settings for project `lab123124`: Android app `suzuki.store` and
/// web app `suzuki-store`. While a value still starts with `PASTE_`, the app
/// runs in DEMO MODE (in-memory sign-in and data) so the UI can be explored.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Values from google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0IO1mDiLALyzJ6eqDgtTLMcBhRbJXJF0',
    appId: '1:672109845281:android:f40a9bbb7dce05c4e57c60',
    messagingSenderId: '672109845281',
    projectId: 'lab123124',
    storageBucket: 'lab123124.firebasestorage.app',
  );

  /// Firebase console → Project settings → Your apps → Web app "suzuki-store".
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0IO1mDiLALyzJ6eqDgtTLMcBhRbJXJF0',
    appId: '1:672109845281:web:23b4e9117780663ae57c60',
    messagingSenderId: '672109845281',
    projectId: 'lab123124',
    authDomain: 'lab123124.firebaseapp.com',
    storageBucket: 'lab123124.firebasestorage.app',
  );

  static FirebaseOptions? get _forPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    return null;
  }

  static FirebaseOptions get currentPlatform =>
      _forPlatform ?? (throw UnsupportedError('Firebase is configured for Android and web only.'));

  static bool get isConfigured {
    final options = _forPlatform;
    return options != null &&
        !options.apiKey.startsWith('PASTE_') &&
        !options.appId.startsWith('PASTE_') &&
        !options.projectId.startsWith('PASTE_');
  }
}
