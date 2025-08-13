import '../../../core/models/data/data_model.dart';
import '../../label/models/label_model.dart';
import '../../../core/models/project/project_model.dart';
import '../../../platform_helpers/storage/get_storage_helper.dart';

/// ✅ Repository: 프로젝트 데이터와 관련된 도메인 연산을 담당
/// - 프로젝트의 CRUD 및 설정 변경을 추상화하여, 도메인 로직과 저장소(StorageHelper) 간의 결합을 낮춤
/// - UseCase는 ProjectRepository만을 의존하므로 테스트가 용이하고, 향후 구현체가 바뀌어도 영향을 최소화함
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
    return list.where((p) => p.id == id).firstOrNull;
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

  /// 🔹 특정 ID의 프로젝트를 삭제 + 라벨도 함께 삭제
  Future<void> deleteById(String id) async {
    final list = await fetchAllProjects();
    final updated = list.where((p) => p.id != id).toList();
    await saveAll(updated);
    await storageHelper.deleteProject(id);
  }

  /// 🔹 모든 프로젝트 삭제 (주의: 라벨은 별도 삭제 필요)
  Future<void> deleteAll() async {
    await saveAll([]);
  }

  /// 🔹 특정 프로젝트의 라벨만 삭제
  Future<void> clearLabels(String projectId) async {
    await storageHelper.deleteProjectLabels(projectId);
  }

  // =========================
  // ⚙️ 프로젝트 속성 변경
  // =========================

  /// 🔹 라벨링 모드 변경 후 저장
  Future<Project?> updateProjectMode(String id, LabelingMode newMode) async {
    final project = await findById(id);
    if (project != null) {
      project.updateMode(newMode);
      await saveProject(project);
    }
    return project;
  }

  /// 🔹 클래스 목록 변경 후 저장
  Future<void> updateProjectClasses(String id, List<String> newClasses) async {
    final project = await findById(id);
    if (project != null) {
      project.updateClasses(newClasses);
      await saveProject(project);
    }
  }

  /// 🔹 이름 변경 후 저장
  Future<Project?> updateProjectName(String id, String newName) async {
    final project = await findById(id);
    if (project != null) {
      project.updateName(newName);
      await saveProject(project);
    }
    return project;
  }

  // =========================
  // 📂 데이터 경로 관리
  // =========================

  /// 🔹 데이터 목록 전체 교체 후 저장
  Future<void> updateDataInfos(String id, List<DataInfo> newDataInfos) async {
    final project = await findById(id);
    if (project != null) {
      project.updateDataInfos(newDataInfos);
      await saveProject(project);
    }
  }

  /// 🔹 단일 데이터 추가 후 저장
  Future<void> addDataInfo(String id, DataInfo newDataInfo) async {
    final project = await findById(id);
    if (project != null) {
      project.addDataInfo(newDataInfo);
      await saveProject(project);
    }
  }

  /// 🔹 특정 데이터 ID 기준으로 제거 후 저장
  Future<void> removeDataInfoById(String id, String dataInfoId) async {
    final project = await findById(id);
    if (project != null) {
      project.removeDataInfoById(dataInfoId);
      await saveProject(project);
    }
  }

  // =========================
  // ⬆️⬇️ 외부 연동
  // =========================

  /// 🔹 외부 파일에서 프로젝트들을 가져옴 (예: JSON)
  Future<List<Project>> importFromExternal() async {
    return await storageHelper.loadProjectFromConfig('import');
  }

  /// 🔹 프로젝트 설정을 외부로 내보냄 (예: 다운로드 가능한 JSON 경로 반환)
  Future<String> exportConfig(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }
}
