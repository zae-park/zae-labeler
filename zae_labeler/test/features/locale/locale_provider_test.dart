// test/features/locale/locale_provider_test.dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/features/locale/providers/locale_provider.dart';

Future<ProviderContainer> _container({Map<String, Object> prefs = const {}, Locale system = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(sp), systemLocaleProvider.overrideWithValue(system)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('저장된 언어가 있으면 그것을 쓴다', () async {
    final c = await _container(prefs: {'user_locale': 'ko'}, system: const Locale('en'));
    expect(c.read(localeProvider), const Locale('ko'));
  });

  test('저장된 언어가 없으면 지원하는 시스템 언어를 쓴다', () async {
    final c = await _container(system: const Locale('ko', 'KR'));
    expect(c.read(localeProvider), const Locale('ko'));
  });

  test('지원하지 않는 시스템 언어면 영어로 시작한다', () async {
    final c = await _container(system: const Locale('fr'));
    expect(c.read(localeProvider), const Locale('en'));
  });

  test('changeLocale은 상태를 바꾸고 저장한다', () async {
    final c = await _container();
    await c.read(localeProvider.notifier).changeLocale('ko');

    expect(c.read(localeProvider), const Locale('ko'));
    expect((await SharedPreferences.getInstance()).getString('user_locale'), 'ko');
  });

  test('지원하지 않는 언어로는 바꾸지 않는다', () async {
    final c = await _container();
    await c.read(localeProvider.notifier).changeLocale('fr');
    expect(c.read(localeProvider), const Locale('en'));
  });
}
