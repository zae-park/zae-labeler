import 'package:flutter/material.dart';

class LocaleViewModel extends ChangeNotifier {
  Locale _currentLocale = const Locale('en'); // Default locale: English

  Locale get currentLocale => _currentLocale;

  void changeLocale(String languageCode) {
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
}
