// 📁 features/locale/view_models/locale_view_model.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zae_labeler/src/core/services/locale_service.dart';
import 'package:zae_labeler/src/features/locale/use_casess/get_locale_use_case.dart';
import 'package:zae_labeler/src/features/locale/use_casess/set_locale_use_case.dart';

class LocaleViewModel extends ChangeNotifier {
  Locale _currentLocale;
  final SetLocaleUseCase _setLocale;

  Locale get currentLocale => _currentLocale;

  LocaleViewModel._({
    required Locale initial,
    required SetLocaleUseCase setLocaleUseCase,
  })  : _currentLocale = initial,
        _setLocale = setLocaleUseCase;

  /// ✅ Factory for initializing with shared preferences
  static Future<LocaleViewModel> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = LocaleService(prefs);
    final getLocale = GetLocaleUseCase(service);
    final setLocale = SetLocaleUseCase(service);

    final initial = await getLocale();
    return LocaleViewModel._(initial: initial, setLocaleUseCase: setLocale);
  }

  Future<void> changeLocale(String langCode) async {
    _currentLocale = Locale(langCode);
    await _setLocale(langCode);
    notifyListeners();
  }
}
