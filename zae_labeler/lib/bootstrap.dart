// lib/bootstrap.dart
//
// 앱 실행 전에 필요한 **런타임 핸들**을 준비하고, 루트 ProviderScope에 넣을 override 목록을 만듭니다.
// - 항상 로컬 Storage로 시작(SwitchableStorageHelper로 래핑) → 로그인 시 authStorageSyncProvider가 핫스왑
// - SharedPreferences 기반 UserPreferenceService
// - LocaleViewModel 비동기 복원
// - FirebaseAuth 핸들
//
// Repository / UseCase는 `core/di/providers.dart`에서 스토리지로부터 파생되므로 여기서 만들지 않습니다.
//
// ⚠️ Firebase.initializeApp()은 main.dart에서 이미 호출합니다.

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/di/providers.dart';
import 'src/core/services/user_preference_service.dart';
import 'src/features/locale/view_models/locale_view_model.dart';
import 'src/platform_helpers/share/interface_share_helper.dart';
import 'src/platform_helpers/share/share_helper_factory.dart';
import 'src/platform_helpers/storage/storage_helper_factory.dart';
import 'src/platform_helpers/storage/switchable_storage_helper.dart';

/// 부트스트랩 결과: 루트 ProviderScope에 주입할 런타임 핸들 묶음.
class BootstrapResult {
  final UserPreferenceService userPrefs;
  final LocaleViewModel localeViewModel;
  final FirebaseAuth firebaseAuth;
  final SwitchableStorageHelper storageHelper;
  final ShareHelperInterface shareHelper;

  const BootstrapResult({
    required this.userPrefs,
    required this.localeViewModel,
    required this.firebaseAuth,
    required this.storageHelper,
    required this.shareHelper,
  });

  /// 루트 `ProviderScope(overrides: ...)`에 그대로 전달합니다.
  List<Override> get overrides => [
    firebaseAuthProvider.overrideWithValue(firebaseAuth),
    switchableStorageProvider.overrideWithValue(storageHelper),
    userPreferenceServiceProvider.overrideWithValue(userPrefs),
    shareHelperProvider.overrideWithValue(shareHelper),
    localeViewModelProvider.overrideWith((ref) => localeViewModel),
  ];
}

/// 앱 실행 전에 한 번 호출해 런타임 핸들을 준비합니다.
///
/// [systemLocale]은 현재 LocaleViewModel 내부의 저장소 기반 복원 로직에 위임합니다.
Future<BootstrapResult> bootstrap({required Locale systemLocale}) async {
  final storage = fb.FirebaseStorage.instance;
  storage.setMaxOperationRetryTime(const Duration(seconds: 12));
  storage.setMaxUploadRetryTime(const Duration(seconds: 12));
  storage.setMaxDownloadRetryTime(const Duration(seconds: 12));

  // 1) Storage/Share: 항상 로컬로 시작하고, Switchable로 래핑
  final switchable = SwitchableStorageHelper(createLocalStorageHelper());
  final share = createLocalShareHelper();

  // 2) 선행 비동기들을 병렬로 수행
  final prefsFuture = SharedPreferences.getInstance();
  final localeFuture = LocaleViewModel.create();
  final userPrefs = UserPreferenceService(await prefsFuture);
  final localeVM = await localeFuture;

  return BootstrapResult(userPrefs: userPrefs, localeViewModel: localeVM, firebaseAuth: FirebaseAuth.instance, storageHelper: switchable, shareHelper: share);
}
