import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferenceService {
  static const _keyLocale = 'user_locale';
  static const _keyDarkMode = 'dark_mode_enabled';
  static const _keyOnboardingSeen = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  UserPreferenceService(this._prefs);

  /// ✅ 언어 설정
  Locale get locale {
    final langCode = _prefs.getString(_keyLocale);
    return langCode != null ? Locale(langCode) : WidgetsBinding.instance.platformDispatcher.locale;
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

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
