// lib/bootstrap.dart
//
// 앱 실행 전에 필요한 **런타임 핸들**을 준비하고, 루트 ProviderScope에 넣을 override 목록을 만듭니다.
// - 항상 로컬 Storage로 시작(SwitchableStorageHelper로 래핑) → 로그인 시 authStorageSyncProvider가 핫스왑
// - SharedPreferences (사용자 설정·언어는 여기서 파생)
// - FirebaseAuth 핸들
//
// Repository / UseCase / 상태(Notifier)는 provider 그래프에서 파생되므로 여기서 만들지 않습니다.
//
// ⚠️ Firebase.initializeApp()은 main.dart에서 이미 호출합니다.

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/di/providers.dart';
import 'src/platform_helpers/share/interface_share_helper.dart';
import 'src/platform_helpers/share/share_helper_factory.dart';
import 'src/platform_helpers/storage/storage_helper_factory.dart';
import 'src/platform_helpers/storage/switchable_storage_helper.dart';

/// 부트스트랩 결과: 루트 ProviderScope에 주입할 런타임 핸들 묶음.
class BootstrapResult {
  final SharedPreferences prefs;
  final Locale systemLocale;
  final FirebaseAuth firebaseAuth;
  final SwitchableStorageHelper storageHelper;
  final ShareHelperInterface shareHelper;

  const BootstrapResult({required this.prefs, required this.systemLocale, required this.firebaseAuth, required this.storageHelper, required this.shareHelper});

  /// 루트 `ProviderScope(overrides: ...)`에 그대로 전달합니다.
  List<Override> get overrides => [
    sharedPreferencesProvider.overrideWithValue(prefs),
    systemLocaleProvider.overrideWithValue(systemLocale),
    firebaseAuthProvider.overrideWithValue(firebaseAuth),
    switchableStorageProvider.overrideWithValue(storageHelper),
    shareHelperProvider.overrideWithValue(shareHelper),
  ];
}

/// 앱 실행 전에 한 번 호출해 런타임 핸들을 준비합니다.
Future<BootstrapResult> bootstrap({required Locale systemLocale}) async {
  final storage = fb.FirebaseStorage.instance;
  storage.setMaxOperationRetryTime(const Duration(seconds: 12));
  storage.setMaxUploadRetryTime(const Duration(seconds: 12));
  storage.setMaxDownloadRetryTime(const Duration(seconds: 12));

  return BootstrapResult(
    prefs: await SharedPreferences.getInstance(),
    systemLocale: systemLocale,
    firebaseAuth: FirebaseAuth.instance,
    storageHelper: SwitchableStorageHelper(createLocalStorageHelper()),
    shareHelper: createLocalShareHelper(),
  );
}
