// 📁 lib/common/i18n.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
