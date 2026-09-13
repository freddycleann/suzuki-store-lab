import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small device-local preferences, such as whether onboarding was completed.
class AppPrefs extends ChangeNotifier {
  AppPrefs(this._prefs);

  static const _onboardingKey = 'onboarding_completed_v1';

  final SharedPreferences _prefs;

  bool get onboardingCompleted => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }
}
