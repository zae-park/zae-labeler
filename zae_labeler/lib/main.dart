/// main.dart
///
/// 엔트리 포인트.
/// - Flutter 엔진 초기화
/// - Firebase 초기화
/// - 시스템 로케일을 읽어 App 루트(ZaeLabeler)에 전달
/// 나머지(Provider, 라우팅, 로컬라이제이션 등)는 app.dart가 담당합니다.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase 초기화 (플랫폼별 옵션)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) 시스템 로케일(없으면 en) 전달
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  final systemLocale = locales.isNotEmpty ? locales.first : const Locale('en');

  // 3) 앱 실행
  runApp(ZaeLabeler(systemLocale: systemLocale));
}
