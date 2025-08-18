// lib/src/features/project/repository/project_repository.dart
import 'package:collection/collection.dart' show IterableExtension; // firstWhereOrNull
import '../../../core/models/data/data_info.dart';
import '../../label/models/label_model.dart';
import '../../../core/models/project/project_model.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';

/// ✅ Repository: 프로젝트 데이터와 관련된 도메인 연산을 담당
/// - CRUD 및 설정 변경을 추상화 (StorageHelper ←→ Domain 사이 결합도↓)
/// - Project는 불변이므로, 모든 '수정'은 copyWith로 새 인스턴스를 생성해 저장
class ProjectRepository {
  final StorageHelperInterface storageHelper;

  ProjectRepository({required this.storageHelper});

  // =========================
  // 📌 기본 CRUD 연산
  // =========================

  /// 🔹 전체 프로젝트 리스트를 불러옵니다.
  Future<List<Project>> fetchAllProjects() async {
    return await storageHelper.loadProjectList();
  }

  /// 🔹 특정 ID의 프로젝트를 찾습니다. 없으면 null 반환
  Future<Project?> findById(String id) async {
    final list = await fetchAllProjects();
    return list.firstWhereOrNull((p) => p.id == id);
    // (컬렉션 의존을 피하려면 try/catch로 firstWhere를 감싸도 됩니다)
  }

  /// 🔹 단일 프로젝트를 저장 (존재 시 갱신, 없으면 추가)
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

  /// 🔹 전체 프로젝트 리스트를 저장소에 반영
  Future<void> saveAll(List<Project> list) async {
    await storageHelper.saveProjectList(list);
  }

  /// 🔹 특정 ID의 프로젝트를 삭제 + 라벨도 함께 삭제(스토리지 기준)
  Future<void> deleteById(String id) async {
    final list = await fetchAllProjects();
    final updated = list.where((p) => p.id != id).toList();
    await saveAll(updated);
    await storageHelper.deleteProject(id);
  }

  /// 🔹 모든 프로젝트 삭제 (주의: 라벨은 별도 삭제 필요)
  Future<void> deleteAll() async {
    // 필요 시 상위 UseCase에서 fetchAllProjects → storageHelper.deleteProject(id) 반복 호출
    await saveAll([]);
  }

  /// 🔹 특정 프로젝트의 라벨만 삭제 (스토리지 측)
  ///
  /// ⚠️ 프로젝트 엔티티 내부의 labels 필드까지 비우고 싶다면
  ///     `clearLabelsInProjectJson`을 추가로 호출하세요.
  Future<void> clearLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  // /// (선택) 🔹 프로젝트 JSON 내부의 labels도 빈 배열로 저장
  // @Deprecated('Use [clearLabels]')
  // Future<void> clearLabelsInProjectJson(String projectId) async {
  //   final project = await findById(projectId);
  //   if (project == null) return;
  //   final updated = project.copyWith(labels: const <LabelModel>[]);
  //   await saveProject(updated);
  // }

  // =========================
  // ⚙️ 프로젝트 속성 변경 (copyWith 기반)
  // =========================

  /// 🔹 라벨링 모드 변경 후 저장
  Future<Project?> updateProjectMode(String id, LabelingMode newMode) async {
    return _update(id, (p) => p.copyWith(mode: newMode));
  }

  /// 🔹 클래스 목록 변경 후 저장
  Future<Project?> updateProjectClasses(String id, List<String> newClasses) async {
    return _update(id, (p) => p.copyWith(classes: List<String>.unmodifiable(newClasses)));
  }

  /// 🔹 이름 변경 후 저장
  Future<Project?> updateProjectName(String id, String newName) async {
    return _update(id, (p) => p.copyWith(name: newName));
  }

  // =========================
  // 📂 데이터 경로 관리 (copyWith 기반)
  // =========================

  /// 🔹 데이터 목록 전체 교체 후 저장
  Future<Project?> updateDataInfos(String id, List<DataInfo> newDataInfos) async {
    return _update(id, (p) => p.copyWith(dataInfos: List<DataInfo>.unmodifiable(newDataInfos)));
  }

  /// 🔹 단일 데이터 추가 후 저장
  Future<Project?> addDataInfo(String id, DataInfo newDataInfo) async {
    return _update(id, (p) {
      if (p.dataInfos.any((e) => e.id == newDataInfo.id)) {
        return p;
      }
      final next = List<DataInfo>.from(p.dataInfos)..add(newDataInfo);
      return p.copyWith(dataInfos: List<DataInfo>.unmodifiable(next));
    });
  }

  /// 🔹 특정 데이터 ID 기준으로 제거 후 저장
  Future<Project?> removeDataInfoById(String id, String dataInfoId) async {
    return _update(id, (p) {
      final next = p.dataInfos.where((d) => d.id != dataInfoId).toList();
      return p.copyWith(dataInfos: List<DataInfo>.unmodifiable(next));
    });
  }

  // =========================
  // ⬆️⬇️ 외부 연동
  // =========================

  /// 🔹 외부 파일에서 프로젝트들을 가져옴 (예: JSON)
  Future<List<Project>> importFromExternal() async {
    try {
      // Native, Web에서만 동작
      return await storageHelper.loadProjectFromConfig('import');
    } catch (_) {
      // Cloud 등 미구현 스토리지에서는 빈 리스트 반환 (상위 UseCase/UI에서 경고/안내)
      return const [];
    }
  }

  /// 🔹 프로젝트 설정을 외부로 내보냄 (예: 다운로드 가능한 JSON 경로 반환)
  Future<String> exportConfig(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  // =========================
  // 🔧 내부 공통 업데이트 헬퍼
  // =========================

  Future<Project?> _update(String id, Project Function(Project) update) async {
    final project = await findById(id);
    if (project == null) return null;
    final updated = update(project);
    await saveProject(updated);
    return updated;
  }
}
