// lib/src/features/locale/providers/locale_provider.dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// 앱이 지원하는 언어.
const supportedLanguageCodes = ['en', 'ko'];

/// 앱 언어 상태.
/// - 초기값: 저장된 언어 → 시스템 언어(지원하는 경우) → 'en'
/// - 변경 시 즉시 상태를 바꾸고 저장합니다.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.watch(localeServiceProvider).loadLocale();
    if (saved != null && supportedLanguageCodes.contains(saved)) return Locale(saved);

    final system = ref.watch(systemLocaleProvider).languageCode;
    return Locale(supportedLanguageCodes.contains(system) ? system : 'en');
  }

  Future<void> changeLocale(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode) || state.languageCode == languageCode) return;
    state = Locale(languageCode);
    await ref.read(localeServiceProvider).saveLocale(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
