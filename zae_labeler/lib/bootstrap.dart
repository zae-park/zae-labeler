/// bootstrap.dart
///
/// 앱 실행 전에 필요한 **런타임 의존성**들을 준비해 반환합니다.
/// - StorageHelper 선택(Prod+Web+로그인 → CloudStorage, 그 외 → 로컬 Storage)
/// - Repository & UseCases 생성
/// - SharedPreferences 기반 UserPreferenceService
/// - LocaleViewModel 비동기 초기화
/// - FirebaseAuth 핸들
///
/// ⚠️ Firebase.initializeApp()은 현재 main.dart에서 이미 호출하므로
/// 여기서는 호출하지 않습니다. (main에서 분리하고 싶다면 main에서 제거하고
/// 이 파일에서 호출하도록 변경해도 됩니다.)

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

import 'src/platform_helpers/storage/interface_storage_helper.dart';
import 'src/platform_helpers/storage/get_storage_helper.dart';
import 'src/platform_helpers/storage/cloud_storage_helper.dart';

/// 의존성 컨테이너: 부트스트랩 결과를 한 번에 담아 위젯 트리에 주입합니다.
class BootstrapResult {
  /// 영속화 추상화 (로컬/클라우드 선택)
  final StorageHelperInterface storageHelper;

  /// 앱 전반 파사드(use-cases 묶음)
  final AppUseCases appUseCases;

  /// 유저 환경설정 서비스 (SharedPreferences 래핑)
  final UserPreferenceService userPrefs;

  /// 로케일 관리 뷰모델 (비동기 생성)
  final LocaleViewModel localeViewModel;

  /// 인증 핸들 (AuthViewModel 생성에 사용)
  final FirebaseAuth firebaseAuth;

  const BootstrapResult(
      {required this.storageHelper, required this.appUseCases, required this.userPrefs, required this.localeViewModel, required this.firebaseAuth});
}

/// 실행 환경에 맞춰 StorageHelper 구현을 선택합니다.
/// - Prod + Web + (로그인됨) → CloudStorageHelper
/// - 그 외 → 로컬(StorageHelper.instance)
Future<StorageHelperInterface> _chooseStorage() async {
  final bool cloudCandidate = isProd && kIsWeb;
  if (cloudCandidate) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 웹 프로덕션 + 로그인 상태 → 클라우드 사용
      return CloudStorageHelper();
    } else {
      // 웹 프로덕션이지만 아직 로그인 전 → 로컬로 폴백
      debugPrint("[bootstrap] Prod+Web 이지만 로그인 정보가 없어 Local Storage로 폴백합니다.");
      return StorageHelper.instance;
    }
  }
  // 개발환경(웹/네이티브) 또는 네이티브 프로덕션 → 로컬
  return StorageHelper.instance;
}

/// 앱 실행 전에 한 번 호출해 의존성을 준비합니다.
///
/// [systemLocale]은 필요 시 LocaleViewModel 초기 기본값 결정 등에 활용할 수 있으나,
/// 현재 구현은 LocaleViewModel 내부의 저장소 기반 복원 로직에 위임합니다.
Future<BootstrapResult> bootstrap({required Locale systemLocale}) async {
  // 1) 실행 환경에 맞춘 Storage 선택 (안전 폴백 포함)
  final storage = await _chooseStorage();

  // 2) Repository & UseCases 구성
  final projectRepo = ProjectRepository(storageHelper: storage);
  final labelRepo = LabelRepository(storageHelper: storage);

  // AppUseCases는 프로젝트/라벨용 유스케이스 파사드를 한데 모은 파사드
  final appUC = AppUseCases.from(
    project: ProjectUseCases.from(projectRepo, labelRepo: labelRepo),
    label: LabelUseCases.from(labelRepo, projectRepo),
  );

  // 3) User preferences & Locale VM
  final prefs = await SharedPreferences.getInstance();
  final userPrefs = UserPreferenceService(prefs);
  final localeVM = await LocaleViewModel.create();

  // 4) Firebase Auth 핸들
  final firebaseAuth = FirebaseAuth.instance;

  return BootstrapResult(storageHelper: storage, appUseCases: appUC, userPrefs: userPrefs, localeViewModel: localeVM, firebaseAuth: firebaseAuth);
}
