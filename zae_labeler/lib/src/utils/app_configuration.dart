import 'package:flutter/material.dart';

class AppConfiguration extends ChangeNotifier {
  String currentLocale;
  bool isDarkMode;

  AppConfiguration({
    this.currentLocale = 'ko',
    this.isDarkMode = false,
  });

  void updateLocale(String newLocale) {
    currentLocale = newLocale;
    notifyListeners();
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
