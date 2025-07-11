import 'package:zae_labeler/src/core/services/locale_service.dart';

class SetLocaleUseCase {
  final LocaleService _service;

  SetLocaleUseCase(this._service);

  Future<void> call(String languageCode) async {
    await _service.saveLocale(languageCode);
  }
}
