import 'package:flutter/material.dart';
import 'package:zae_labeler/src/core/services/locale_service.dart';

class GetLocaleUseCase {
  final LocaleService _service;

  GetLocaleUseCase(this._service);

  Future<Locale> call() async {
    final langCode = await _service.loadLocale();
    return langCode != null ? Locale(langCode) : const Locale('en');
  }
}
