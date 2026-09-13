import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Free key from https://api-ninjas.com used for full technical specs.
  /// Run with `flutter run --dart-define=API_NINJAS_KEY=your_key`
  /// or paste the key as the defaultValue.
  static const apiNinjasKey = String.fromEnvironment(
    'API_NINJAS_KEY',
    defaultValue: 'ITt5MRxKYutdRbBvR9b6ieiC2gTfhkFep3qN8sxF',
  );

  static bool get hasApiNinjasKey => apiNinjasKey.trim().isNotEmpty;

  /// OAuth web client ID from google-services.json (the oauth_client with
  /// client_type 3). Google sign-in on Android needs it to issue an ID token
  /// that Firebase Auth accepts.
  static const googleWebClientId = '672109845281-ic6h5q6gu9tc5jkimactgnmr06e9st36.apps.googleusercontent.com';

  /// Wikimedia asks API clients to identify themselves with a User-Agent.
  static const userAgent = 'SuzukiMotoApp/1.0 (Flutter lab project)';

  /// Browsers forbid setting User-Agent, so it is only sent from mobile builds.
  static Map<String, String> get identityHeaders => kIsWeb ? const {} : const {'User-Agent': userAgent};
}
