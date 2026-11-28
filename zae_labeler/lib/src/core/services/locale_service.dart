import 'package:shared_preferences/shared_preferences.dart';

/// 사용자가 선택한 언어 코드를 SharedPreferences에 보관합니다.
class LocaleService {
  final SharedPreferences _prefs;

  static const _key = 'user_locale';

  LocaleService(this._prefs);

  Future<void> saveLocale(String languageCode) async {
    await _prefs.setString(_key, languageCode);
  }

  /// 저장된 언어 코드(없으면 null). SharedPreferences는 메모리 캐시를 쓰므로 동기로 읽습니다.
  String? loadLocale() => _prefs.getString(_key);
}
