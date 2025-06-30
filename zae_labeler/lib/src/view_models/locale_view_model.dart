import 'package:flutter/material.dart';
import 'package:zae_labeler/src/core/services/user_preference_service.dart';

class LocaleViewModel extends ChangeNotifier {
  Locale _currentLocale;
  final UserPreferenceService _preferenceService;

  Locale get currentLocale => _currentLocale;

  /// ✅ 생성 시 저장된 로케일을 초기화하거나 주입된 값 사용
  LocaleViewModel({required UserPreferenceService preferenceService, Locale? initial})
      : _preferenceService = preferenceService,
        _currentLocale = initial ?? preferenceService.locale;

  /// ✅ 로케일 변경 시 SharedPreferences에 저장까지 수행
  Future<void> changeLocale(String languageCode) async {
    _currentLocale = Locale(languageCode);
    notifyListeners();
    await _preferenceService.setLocale(_currentLocale);
  }
}
