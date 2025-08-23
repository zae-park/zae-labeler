// lib/src/features/project/repository/project_repository.dart
import 'package:collection/collection.dart' show IterableExtension; // firstWhereOrNull
import 'package:zae_labeler/src/core/models/label/label_types.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/project/project_model.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';

/// ✅ Repository: 프로젝트 데이터의 영속화(CRUD)와 단일 속성 변경만 담당
/// - StorageHelper ←→ Domain 사이의 얇은 어댑터
/// - Project는 불변 가정: 수정 시 copyWith로 새 인스턴스 생성 후 저장
/// - 라벨 삭제/검증/통계/일괄 시나리오는 UseCase 또는 LabelRepository가 담당
class ProjectRepository {
  final StorageHelperInterface storageHelper;

  ProjectRepository({required this.storageHelper});

  // =========================
  // 📌 기본 CRUD 연산
  // =========================

  /// 전체 프로젝트 리스트를 로드합니다.
  /// @return 저장소에 존재하는 모든 [Project] 목록.
  Future<List<Project>> fetchAllProjects() async {
    return await storageHelper.loadProjectList();
  }

  /// ID로 단일 프로젝트를 조회합니다.
  /// @param id 찾을 프로젝트 식별자
  /// @return 일치 항목이 없으면 `null`.
  Future<Project?> findById(String id) async {
    final list = await fetchAllProjects();
    return list.firstWhereOrNull((p) => p.id == id);
  }

  /// 단일 프로젝트를 저장합니다.
  /// - 동일 ID가 존재하면 교체, 없으면 추가합니다.
  /// - 내부적으로 전체 리스트 스냅샷을 저장합니다.
  /// @param project 저장할 프로젝트
  Future<void> saveProject(Project project) async {
    final current = await fetchAllProjects();
    final index = current.indexWhere((p) => p.id == project.id);

    if (index != -1) {
      current[index] = project;
    } else {
      current.add(project);
    }
    await saveAll(current);
  }

  /// 전체 프로젝트 리스트 스냅샷을 저장합니다.
  /// @param list 저장할 전체 [Project] 배열
  Future<void> saveAll(List<Project> list) async {
    await storageHelper.saveProjectList(list);
  }

  /// 프로젝트를 삭제합니다.
  /// - 리스트에서 제거 후, 스토리지 레벨에서 **라벨 포함(cascade)** 삭제가 수행됩니다.
  /// @param id 삭제할 프로젝트 ID
  Future<void> deleteById(String id) async {
    final list = await fetchAllProjects();
    final updated = list.where((p) => p.id != id).toList();
    await saveAll(updated);
    await storageHelper.deleteProject(id); // ⚠️ labels도 함께 삭제됨(스토리지 구현에 위임)
  }

  /// 모든 프로젝트를 삭제합니다.
  /// - 여기서는 프로젝트 리스트만 비웁니다.
  /// - 라벨/부수 자원까지 완전 삭제하려면 상위 UseCase에서
  ///   각 프로젝트에 대해 [storageHelper.deleteProject]를 호출하세요.
  Future<void> deleteAll() async {
    await saveAll([]);
  }

  /// (임시) 특정 프로젝트의 라벨만 스토리지에서 삭제합니다.
  /// - 경계상 LabelRepository/UseCase 책임이므로, 향후 오케스트레이션으로 이전 권장.
  /// @param projectId 라벨을 제거할 프로젝트 ID
  @Deprecated('Use LabelRepository.clearAll(projectId) 또는 UseCase에서 오케스트레이션하세요.')
  Future<void> clearLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  // =========================
  // ⚙️ 프로젝트 속성 변경 (copyWith 기반)
  // =========================

  /// 라벨링 모드를 변경합니다. (라벨 초기화는 수행하지 않음)
  /// - 모드 변경과 라벨 초기화를 함께 하고 싶다면 UseCase에서
  ///   LabelRepository.clearAll → updateProjectMode 순으로 오케스트레이션하세요.
  /// @param id 프로젝트 ID
  /// @param newMode 새 라벨링 모드
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> updateProjectMode(String id, LabelingMode newMode) async {
    return _update(id, (p) => p.copyWith(mode: newMode));
  }

  /// 클래스 목록을 변경합니다.
  /// @param id 프로젝트 ID
  /// @param newClasses 새 클래스 목록
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> updateProjectClasses(String id, List<String> newClasses) async {
    return _update(id, (p) => p.copyWith(classes: List<String>.unmodifiable(newClasses)));
  }

  /// 프로젝트 이름을 변경합니다.
  /// @param id 프로젝트 ID
  /// @param newName 새 이름
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> updateProjectName(String id, String newName) async {
    return _update(id, (p) => p.copyWith(name: newName));
  }

  // =========================
  // 📂 DataInfo 관리 (copyWith 기반)
  // =========================

  /// 데이터 소스 목록을 통째로 교체합니다.
  /// @param id 프로젝트 ID
  /// @param newDataInfos 새 데이터 목록
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> updateDataInfos(String id, List<DataInfo> newDataInfos) async {
    return _update(id, (p) => p.copyWith(dataInfos: List<DataInfo>.unmodifiable(newDataInfos)));
  }

  /// 데이터 소스를 1건 추가합니다. (중복 ID는 무시)
  /// @param id 프로젝트 ID
  /// @param newDataInfo 추가할 데이터
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> addDataInfo(String id, DataInfo newDataInfo) async {
    return _update(id, (p) {
      if (p.dataInfos.any((e) => e.id == newDataInfo.id)) return p;
      final next = List<DataInfo>.from(p.dataInfos)..add(newDataInfo);
      return p.copyWith(dataInfos: List<DataInfo>.unmodifiable(next));
    });
  }

  /// 특정 데이터 ID를 제거합니다.
  /// @param id 프로젝트 ID
  /// @param dataInfoId 제거할 데이터 ID
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> removeDataInfoById(String id, String dataInfoId) async {
    return _update(id, (p) {
      final next = p.dataInfos.where((d) => d.id != dataInfoId).toList();
      return p.copyWith(dataInfos: List<DataInfo>.unmodifiable(next));
    });
  }

  // =========================
  // ⬆️⬇️ 외부 연동
  // =========================

  /// 외부 설정 파일(예: JSON)에서 프로젝트들을 복원합니다.
  /// - Web/Native에서만 의미가 있으며, Cloud 구현에서는 미구현일 수 있습니다.
  /// - 미구현 스토리지에서는 빈 배열을 반환합니다(상위에서 안내 처리 권장).
  Future<List<Project>> importFromExternal() async {
    try {
      // Native, Web에서만 동작
      return await storageHelper.loadProjectFromConfig('import');
    } catch (_) {
      // Cloud 등 미구현 스토리지에서는 빈 리스트 반환 (상위 UseCase/UI에서 경고/안내)
      return const [];
    }
  }

  /// 단일 프로젝트 설정을 외부(JSON)로 내보냅니다.
  /// - Web에서는 브라우저 다운로드를 트리거합니다.
  /// - Native/Cloud에서는 스토리지 구현에 따라 미지원일 수 있습니다.
  /// @return 생성/다운로드된 파일 경로 또는 설명 문자열.
  Future<String> exportConfig(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  // =========================
  // 🔧 내부 공통 업데이트 헬퍼
  // =========================

  /// 공통 업데이트 헬퍼: 프로젝트를 조회 → 변환 → 저장 → 반환합니다.
  /// @param id 프로젝트 ID
  /// @param update 기존 프로젝트를 입력받아 갱신본을 반환하는 변환 함수
  /// @return 갱신된 [Project] 또는 `null`.
  Future<Project?> _update(String id, Project Function(Project) update) async {
    final project = await findById(id);
    if (project == null) return null;
    final updated = update(project);
    await saveProject(updated);
    return updated;
  }
}
