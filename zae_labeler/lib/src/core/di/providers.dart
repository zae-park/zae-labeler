// lib/src/core/di/providers.dart
//
// 앱 전역 의존성 그래프 (Riverpod).
//
// - 런타임에만 만들 수 있는 값(FirebaseAuth, SharedPreferences 기반 서비스, 스토리지 등)은
//   `bootstrap()` 결과로 루트 `ProviderScope`에서 override 합니다.
// - Repository / UseCase는 스토리지 provider로부터 파생되므로 override할 필요가 없습니다.
//   테스트에서는 `storageHelperProvider`만 override하면 하위 그래프가 모두 따라옵니다.
// - 스토리지 핫스왑은 `SwitchableStorageHelper`가 내부 delegate를 바꾸는 방식이므로
//   Repository/UseCase 인스턴스는 재생성되지 않아도 항상 현재 스토리지를 사용합니다.
import 'dart:ui' show Locale;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/label/repository/label_repository.dart';
import '../../features/label/use_cases/label_use_cases.dart';
import '../../features/project/logic/project_validator.dart';
import '../../features/project/repository/project_repository.dart';
import '../../features/project/use_cases/edit_project_use_case.dart';
import '../../features/project/use_cases/project_use_cases.dart';
import '../../platform_helpers/pickers/data_info_picker.dart';
import '../../platform_helpers/share/interface_share_helper.dart';
import '../../platform_helpers/storage/interface_storage_helper.dart';
import '../../platform_helpers/storage/switchable_storage_helper.dart';
import '../services/locale_service.dart';
import '../services/user_preference_service.dart';
import '../use_cases/app_use_cases.dart';

Never _mustOverride(String name) => throw UnimplementedError('$name must be overridden in the root ProviderScope (see bootstrap.dart).');

// ─────────────────────────────────────────────────────────────────────────────
// Runtime handles (root ProviderScope에서 override)
// ─────────────────────────────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => _mustOverride('firebaseAuthProvider'));

/// 로컬/클라우드 간 핫스왑 가능한 스토리지. 로그인 상태 동기화에서만 직접 사용합니다.
final switchableStorageProvider = Provider<SwitchableStorageHelper>((ref) => _mustOverride('switchableStorageProvider'));

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => _mustOverride('sharedPreferencesProvider'));

/// 기기(시스템) 로케일. 저장된 언어가 없을 때 기본값으로 사용합니다.
final systemLocaleProvider = Provider<Locale>((ref) => const Locale('en'));

final shareHelperProvider = Provider<ShareHelperInterface>((ref) => _mustOverride('shareHelperProvider'));

// ─────────────────────────────────────────────────────────────────────────────
// Storage → Repository → UseCase
// ─────────────────────────────────────────────────────────────────────────────

/// 앱 코드가 사용하는 스토리지 인터페이스. 기본값은 switchable 스토리지입니다.
final storageHelperProvider = Provider<StorageHelperInterface>((ref) => ref.watch(switchableStorageProvider));

final projectRepositoryProvider = Provider<ProjectRepository>((ref) => ProjectRepository(storageHelper: ref.watch(storageHelperProvider)));

final labelRepositoryProvider = Provider<LabelRepository>((ref) => LabelRepository(storageHelper: ref.watch(storageHelperProvider)));

final labelUseCasesProvider = Provider<LabelUseCases>((ref) => LabelUseCases.from(ref.watch(labelRepositoryProvider), ref.watch(projectRepositoryProvider)));

final projectUseCasesProvider = Provider<ProjectUseCases>((ref) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  final labelRepo = ref.watch(labelRepositoryProvider);
  final editor = EditProjectUseCase(projectRepository: projectRepo, labelRepository: labelRepo, validator: ProjectValidator());
  return ProjectUseCases.from(projectRepo, labelRepo: labelRepo, editor: editor);
});

final appUseCasesProvider = Provider<AppUseCases>(
  (ref) => AppUseCases.from(project: ref.watch(projectUseCasesProvider), label: ref.watch(labelUseCasesProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Preferences / Platform services
// ─────────────────────────────────────────────────────────────────────────────

final userPreferenceServiceProvider = Provider<UserPreferenceService>((ref) => UserPreferenceService(ref.watch(sharedPreferencesProvider)));

final localeServiceProvider = Provider<LocaleService>((ref) => LocaleService(ref.watch(sharedPreferencesProvider)));

/// 플랫폼 인지형 Picker (Web은 업로드 후 URL, Native는 절대경로)
final dataInfoPickerProvider = Provider<DataInfoPicker>((ref) => createDataInfoPicker(auth: ref.watch(firebaseAuthProvider)));

/// 스토리지가 로컬↔클라우드로 바뀔 때마다 1씩 증가합니다.
/// 저장소 내용을 캐시하는 provider(프로젝트 목록, 진행률 요약)는 이것을 watch해 자동으로 다시 읽습니다.
class StorageRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final storageRevisionProvider = NotifierProvider<StorageRevision, int>(StorageRevision.new);

/// 로그인 상태 변화에 맞춰 스토리지를 로컬/클라우드로 전환합니다.
/// 루트 위젯에서 watch하면 앱이 살아있는 동안 구독이 유지됩니다.
/// - `authStateChanges()`는 구독 즉시 현재 상태를 한 번 방출하므로 초기 동기화도 함께 처리됩니다.
/// - 실제로 모드가 바뀐 경우에만 전환하고 [storageRevisionProvider]를 올립니다(시작 시 불필요한 재로딩 방지).
final authStorageSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final storage = ref.watch(switchableStorageProvider);
  var isCloud = false; // bootstrap은 항상 로컬로 시작
  final sub = auth.authStateChanges().listen((user) {
    final wantCloud = user != null;
    if (wantCloud == isCloud) return;
    isCloud = wantCloud;
    wantCloud ? storage.switchToCloud() : storage.switchToLocal();
    ref.read(storageRevisionProvider.notifier).bump();
  });
  ref.onDispose(sub.cancel);
});
