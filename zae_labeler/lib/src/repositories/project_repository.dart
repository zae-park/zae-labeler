import '../models/project_model.dart';
import '../utils/storage_helper.dart';

/// ✅ Repository: 프로젝트 관련 데이터 연산을 관리하는 도메인 중심 인터페이스
/// - 프로젝트의 CRUD 연산을 추상화하여 도메인 로직과 데이터 저장소(StorageHelper) 간의 의존성을 분리합니다.
/// - UseCase는 이 Repository만을 의존함으로써 테스트가 용이하고, 향후 데이터 저장 방식이 변경되더라도 UseCase 로직은 영향을 받지 않게 됩니다.
class ProjectRepository {
  final StorageHelperInterface storageHelper;

  ProjectRepository({required this.storageHelper});

  /// 🔹 전체 프로젝트 리스트를 불러옵니다.
  /// - 저장소(StorageHelper)로부터 현재 저장된 모든 프로젝트를 가져옵니다.
  Future<List<Project>> fetchAllProjects() async {
    return await storageHelper.loadProjectList();
  }

  /// 🔹 ID를 기준으로 특정 프로젝트를 찾습니다.
  /// - 내부적으로 전체 프로젝트를 로드한 후 ID 기준으로 검색합니다.
  /// - 일치하는 프로젝트가 없으면 null을 반환합니다.
  Future<Project?> findById(String id) async {
    final list = await fetchAllProjects();
    return list.where((p) => p.id == id).firstOrNull;
  }

  /// 🔹 단일 프로젝트를 저장합니다.
  /// - 동일한 ID가 존재하면 해당 항목을 업데이트하고, 존재하지 않으면 새로 추가합니다.
  /// - 변경된 전체 리스트를 저장소에 반영합니다.
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

  /// 🔹 전체 프로젝트 리스트를 저장합니다.
  /// - 현재 리스트를 통째로 덮어쓰며 저장소에 반영합니다.
  Future<void> saveAll(List<Project> list) async {
    await storageHelper.saveProjectList(list);
  }

  /// 🔹 특정 프로젝트를 ID 기준으로 삭제합니다.
  /// - 삭제 후 저장소에 저장된 전체 리스트를 갱신합니다.
  /// - 해당 프로젝트에 저장된 라벨 정보도 함께 제거합니다.
  Future<void> deleteById(String id) async {
    final list = await fetchAllProjects();
    final updated = list.where((p) => p.id != id).toList();
    await saveAll(updated);
    await storageHelper.deleteProjectLabels(id);
  }

  /// 🔹 전체 프로젝트를 삭제합니다.
  /// - 빈 리스트를 저장하여 모든 프로젝트를 제거합니다.
  /// - (주의) 라벨 데이터는 삭제되지 않으므로 별도 처리 필요 시 추가 구현 필요합니다.
  Future<void> deleteAll() async {
    await saveAll([]);
  }

  /// 🔹 외부에서 프로젝트를 가져옵니다.
  /// - 예: JSON import → 파일을 파싱하여 여러 개의 프로젝트를 불러올 수 있음
  /// - 내부적으로는 `storageHelper.loadProjectFromConfig()`를 호출합니다.
  Future<List<Project>> importFromExternal() async {
    return await storageHelper.loadProjectFromConfig('import');
  }

  /// 🔹 프로젝트 설정을 외부로 내보냅니다.
  /// - 프로젝트의 메타데이터를 JSON 형식으로 저장하거나 다운로드 가능한 경로를 반환합니다.
  Future<String> exportConfig(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  Future<void> clearLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }
}
