import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  final SharedPreferences _prefs;

  static const _key = 'user_locale';

  LocaleService(this._prefs);

  Future<void> saveLocale(String languageCode) async {
    await _prefs.setString(_key, languageCode);
  }

  Future<String?> loadLocale() async {
    return _prefs.getString(_key);
  }
}
