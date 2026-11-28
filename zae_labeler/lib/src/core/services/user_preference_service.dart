import 'package:shared_preferences/shared_preferences.dart';

/// 언어 설정은 [LocaleService]가 담당합니다.
class UserPreferenceService {
  static const _keyDarkMode = 'dark_mode_enabled';
  static const _keyOnboardingSeen = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  UserPreferenceService(this._prefs);

  /// ✅ 다크 모드
  bool get isDarkModeEnabled => _prefs.getBool(_keyDarkMode) ?? false;

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool(_keyDarkMode, enabled);
  }

  /// ✅ 온보딩 여부
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboardingSeen) ?? false;

  Future<void> setHasSeenOnboarding(bool seen) async {
    await _prefs.setBool(_keyOnboardingSeen, seen);
  }
}
