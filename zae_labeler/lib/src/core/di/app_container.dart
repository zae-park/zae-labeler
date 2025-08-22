import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zae_labeler/src/core/services/user_preference_service.dart';

import '../../features/project/repository/project_repository.dart';
import '../../features/label/repository/label_repository.dart';

import '../../features/project/use_cases/project_use_cases.dart';
import '../../features/label/use_cases/label_use_cases.dart';
import '../../core/use_cases/app_use_cases.dart';

import '../../platform_helpers/storage/interface_storage_helper.dart';
import '../../platform_helpers/storage/storage_helper_factory.dart';
import '../../platform_helpers/storage/cloud_storage_helper.dart';
import '../../platform_helpers/share/interface_share_helper.dart';

import '../../features/locale/view_models/locale_view_model.dart';

import '../../../env.dart';

// TODO: Hot Swap 가능한 의존성 컨테이너
class AppContainer extends ChangeNotifier {
  // 고정 의존성
  final UserPreferenceService userPrefs;
  final LocaleViewModel localeViewModel;
  final FirebaseAuth firebaseAuth;
  final ShareHelperInterface shareHelper;

  // 가변 의존성(핫스왑 대상)
  StorageHelperInterface _storage;
  late ProjectRepository _projectRepo;
  late LabelRepository _labelRepo;
  late AppUseCases _appUseCases;

  // 간단한 generation 카운터 — 의존하는 VM/위젯 재생성 트리거로 사용 가능
  int _generation = 0;

  AppContainer({
    required this.userPrefs,
    required this.localeViewModel,
    required this.firebaseAuth,
    required this.shareHelper,
    required StorageHelperInterface storage,
  }) : _storage = storage {
    _rebuildGraph();
    _attachAuthListener(); // 로그인 변화를 감지해서 스토리지 핫스왑
  }

  // ─ getters ─
  StorageHelperInterface get storage => _storage;
  AppUseCases get appUseCases => _appUseCases;
  ProjectRepository get projectRepo => _projectRepo;
  LabelRepository get labelRepo => _labelRepo;
  int get generation => _generation;

  // ─ 의존 그래프 재구성 ─
  void _rebuildGraph() {
    _projectRepo = ProjectRepository(storageHelper: _storage);
    _labelRepo = LabelRepository(storageHelper: _storage);

    _appUseCases = AppUseCases.from(
      project: ProjectUseCases.from(_projectRepo, labelRepo: _labelRepo),
      label: LabelUseCases.from(_labelRepo, _projectRepo),
    );

    _generation++; // 바뀌었음을 알리기 위한 간단한 버전업
    notifyListeners();
  }

  Future<void> switchStorage(StorageHelperInterface next) async {
    if (identical(_storage, next) || _storage.runtimeType == next.runtimeType) return;
    _storage = next;
    _rebuildGraph();
  }

  void _attachAuthListener() {
    firebaseAuth.authStateChanges().listen((user) async {
      // Prod + Web 에서만 클라우드로 승격 / 로컬로 폴백
      if (!(isProd && kIsWeb)) return;

      final StorageHelperInterface next = (user != null) ? CloudStorageHelper() : createLocalStorageHelper();

      await switchStorage(next);
    });
  }
}
