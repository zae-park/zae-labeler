// lib/bootstrap.dart

//
// 앱 실행 전에 필요한 **런타임 의존성**들을 준비해 반환합니다.
// - 항상 로컬 Storage로 시작(SwitchableStorageHelper로 래핑)
// - Repository & UseCases 생성
// - SharedPreferences 기반 UserPreferenceService
// - LocaleViewModel 비동기 초기화
// - FirebaseAuth 핸들
//
// ⚠️ Firebase.initializeApp()은 현재 main.dart에서 이미 호출하므로

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zae_labeler/src/features/project/logic/project_validator.dart';
import 'package:zae_labeler/src/features/project/use_cases/edit_project_use_case.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb;
import 'package:zae_labeler/src/platform_helpers/storage/cloud_storage_helper.dart';
import 'package:zae_labeler/src/platform_helpers/storage/storage_policies.dart';

import 'src/core/services/user_preference_service.dart';
import 'src/features/locale/view_models/locale_view_model.dart';

import 'src/core/use_cases/app_use_cases.dart';
import 'src/features/label/use_cases/label_use_cases.dart';
import 'src/features/project/use_cases/project_use_cases.dart';

import 'src/features/label/repository/label_repository.dart';
import 'src/features/project/repository/project_repository.dart';

// ✅ 인터페이스
import 'src/platform_helpers/storage/interface_storage_helper.dart';
import 'src/platform_helpers/share/interface_share_helper.dart';
// ✅ 로컬 구현 선택 팩토리 (web/native/stub 조건부 import)
import 'src/platform_helpers/storage/storage_helper_factory.dart';
import 'src/platform_helpers/share/share_helper_factory.dart';
// ✅ 스위치 가능 스토리지
import 'src/platform_helpers/storage/switchable_storage_helper.dart';

/// 의존성 컨테이너: 부트스트랩 결과를 한 번에 담아 위젯 트리에 주입합니다.
class BootstrapResult {
  final AppUseCases appUseCases;
  final UserPreferenceService userPrefs;
  final LocaleViewModel localeViewModel;
  final FirebaseAuth firebaseAuth;
  final StorageHelperInterface storageHelper; // 실제 인스턴스는 SwitchableStorageHelper
  final ShareHelperInterface shareHelper;

  const BootstrapResult({
    required this.appUseCases,
    required this.userPrefs,
    required this.localeViewModel,
    required this.firebaseAuth,
    required this.storageHelper,
    required this.shareHelper,
  });
}

// 🔽 A안: 항상 로컬로 시작(핫스왑은 앱 루트에서 auth 이벤트로 수행)
Future<ShareHelperInterface> _chooseShareHelper() async {
  return createLocalShareHelper();
}

/// 앱 실행 전에 한 번 호출해 의존성을 준비합니다.
///
/// [systemLocale]은 필요 시 LocaleViewModel 초기 기본값 결정 등에 활용할 수 있으나,
/// 현재 구현은 LocaleViewModel 내부의 저장소 기반 복원 로직에 위임합니다.
Future<BootstrapResult> bootstrap({required Locale systemLocale}) async {
  final storage = fb.FirebaseStorage.instance;
  storage.setMaxOperationRetryTime(const Duration(seconds: 12));
  storage.setMaxUploadRetryTime(const Duration(seconds: 12));
  storage.setMaxDownloadRetryTime(const Duration(seconds: 12));

  // 1) Storage/Share 준비: 항상 로컬로 시작하고, Switchable로 래핑
  final switchable = SwitchableStorageHelper.explicit(
    local: createLocalStorageHelper(),
    cloud: CloudStorageHelper(),
    initialMode: StorageMode.local, // 로그인해도 기본 로컬
    readPolicy: ReadPolicy.auto, // 요약=cloud 우선, 에셋=local 우선 등 내부 판단
    writePolicy: WritePolicy.localOnly,
  );
  final share = await _chooseShareHelper();

  // 2) 선행 비동기들을 병렬로 수행
  final prefsFuture = SharedPreferences.getInstance();
  final localeFuture = LocaleViewModel.create();

  final prefs = await prefsFuture;
  final userPrefs = UserPreferenceService(prefs);
  final localeVM = await localeFuture;

  // 3) Repository & UseCases 구성 (Switchable 주입)
  final projectRepo = ProjectRepository(storageHelper: switchable);
  final labelRepo = LabelRepository(storageHelper: switchable);
  final projectEditUC = EditProjectUseCase(projectRepository: projectRepo, labelRepository: labelRepo, validator: ProjectValidator());

  final appUC = AppUseCases.from(
    project: ProjectUseCases.from(projectRepo, labelRepo: labelRepo, editor: projectEditUC),
    label: LabelUseCases.from(labelRepo, projectRepo),
  );

  // 4) Firebase Auth 핸들
  final firebaseAuth = FirebaseAuth.instance;

  return BootstrapResult(
    appUseCases: appUC,
    userPrefs: userPrefs,
    localeViewModel: localeVM,
    firebaseAuth: firebaseAuth,
    storageHelper: switchable,
    shareHelper: share,
  );
}
