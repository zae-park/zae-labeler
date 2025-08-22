// lib/bootstrap.dart

//
// 앱 실행 전에 필요한 **런타임 의존성**들을 준비해 반환합니다.
// - StorageHelper 선택(Prod+Web+로그인 → CloudStorage, 그 외 → 로컬 Storage)
// - Repository & UseCases 생성
// - SharedPreferences 기반 UserPreferenceService
// - LocaleViewModel 비동기 초기화
// - FirebaseAuth 핸들
//
// ⚠️ Firebase.initializeApp()은 현재 main.dart에서 이미 호출하므로

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env.dart';
import 'src/core/services/user_preference_service.dart';
import 'src/features/locale/view_models/locale_view_model.dart';

import 'src/core/use_cases/app_use_cases.dart';
import 'src/features/label/use_cases/label_use_cases.dart';
import 'src/features/project/use_cases/project_use_cases.dart';

import 'src/features/label/repository/label_repository.dart';
import 'src/features/project/repository/project_repository.dart';

// ✅ 타입 선언 (interface)
import 'src/platform_helpers/storage/interface_storage_helper.dart';
import 'src/platform_helpers/share/interface_share_helper.dart';
// ✅ 로컬 구현 선택 팩토리 (web/native/stub를 조건부 import로 매핑)
import 'src/platform_helpers/storage/storage_helper_factory.dart';
import 'src/platform_helpers/share/share_helper_factory.dart';
// ✅ 클라우드 구현
import 'src/platform_helpers/storage/cloud_storage_helper.dart';

/// 의존성 컨테이너: 부트스트랩 결과를 한 번에 담아 위젯 트리에 주입합니다.
class BootstrapResult {
  final AppUseCases appUseCases; // 앱 전반 파사드(use-cases 묶음)
  final UserPreferenceService userPrefs; // 유저 환경설정 서비스 (SharedPreferences 래핑)
  final LocaleViewModel localeViewModel; // 로케일 관리 뷰모델 (비동기 생성)
  final FirebaseAuth firebaseAuth; // 인증 핸들 (AuthViewModel 생성에 사용)
  final StorageHelperInterface storageHelper; // 영속화 추상화 (로컬/클라우드 선택)
  final ShareHelperInterface shareHelper;

  const BootstrapResult(
      {required this.appUseCases,
      required this.userPrefs,
      required this.localeViewModel,
      required this.firebaseAuth,
      required this.storageHelper,
      required this.shareHelper});
}

Future<User?> _awaitInitialAuth({Duration timeout = const Duration(milliseconds: 400)}) async {
  final auth = FirebaseAuth.instance;
  // 이미 로그인 돼 있으면 그대로 반환
  if (auth.currentUser != null) return auth.currentUser;
  try {
    // 첫 auth 이벤트를 잠깐만 기다린다(웹에서 초반 지연 보완)
    return await auth.authStateChanges().first.timeout(timeout);
  } catch (_) {
    return auth.currentUser; // 여전히 null이면 null
  }
}

/// 실행 환경에 맞춰 StorageHelper 구현을 선택합니다.
/// - Prod + Web + (로그인됨) → CloudStorageHelper
/// - 그 외 → 로컬(createLocalStorageHelper)
Future<StorageHelperInterface> _chooseStorage() async {
  if (isProd && kIsWeb) {
    final user = await _awaitInitialAuth(); // ← 실제로 사용
    if (user != null) {
      // 필요하면 UID 주입:
      // return CloudStorageHelper(userId: user.uid);
      return CloudStorageHelper();
    } else {
      debugPrint("[bootstrap] Prod+Web 이지만 로그인 정보가 없어 Local Storage로 폴백합니다.");
      return createLocalStorageHelper();
    }
  }
  // 개발환경(웹/네이티브) 또는 네이티브 프로덕션 → 로컬
  return createLocalStorageHelper();
}

Future<ShareHelperInterface> _chooseShareHelper() async {
  return createLocalShareHelper();
}

/// 앱 실행 전에 한 번 호출해 의존성을 준비합니다.
///
/// [systemLocale]은 필요 시 LocaleViewModel 초기 기본값 결정 등에 활용할 수 있으나,
/// 현재 구현은 LocaleViewModel 내부의 저장소 기반 복원 로직에 위임합니다.
Future<BootstrapResult> bootstrap({required Locale systemLocale}) async {
  // 1) 실행 환경에 맞춘 Storage/Share 선택
  final storage = await _chooseStorage();
  final share = await _chooseShareHelper();

  // 2) 선행 비동기들을 병렬로 수행 (조금 더 빠르게 시작)
  final prefsFuture = SharedPreferences.getInstance();
  final localeFuture = LocaleViewModel.create();

  final prefs = await prefsFuture;
  final userPrefs = UserPreferenceService(prefs);
  final localeVM = await localeFuture;

  // 3) Repository & UseCases 구성
  final projectRepo = ProjectRepository(storageHelper: storage);
  final labelRepo = LabelRepository(storageHelper: storage);

  final appUC = AppUseCases.from(project: ProjectUseCases.from(projectRepo, labelRepo: labelRepo), label: LabelUseCases.from(labelRepo, projectRepo));

  // 4) Firebase Auth 핸들
  final firebaseAuth = FirebaseAuth.instance;

  return BootstrapResult(
      appUseCases: appUC, userPrefs: userPrefs, localeViewModel: localeVM, firebaseAuth: firebaseAuth, storageHelper: storage, shareHelper: share);
}
