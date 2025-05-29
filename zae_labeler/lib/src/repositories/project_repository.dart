import '../models/project_model.dart';
import '../utils/storage_helper.dart';

/// ✅ Repository: 프로젝트 관련 데이터 연산을 관리하는 도메인 중심 인터페이스
class ProjectRepository {
  final StorageHelperInterface storageHelper;

  ProjectRepository({required this.storageHelper});

  /// 모든 프로젝트 불러오기
  Future<List<Project>> fetchAllProjects() async {
    return await storageHelper.loadProjectList();
  }

  /// ID로 프로젝트 찾기
  Future<Project?> findById(String id) async {
    final list = await fetchAllProjects();
    return list.where((p) => p.id == id).firstOrNull;
  }

  /// 프로젝트 저장 (단일)
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

  /// 프로젝트 저장 (전체)
  Future<void> saveAll(List<Project> list) async {
    await storageHelper.saveProjectList(list);
  }

  /// 프로젝트 삭제
  Future<void> deleteById(String id) async {
    final list = await fetchAllProjects();
    final updated = list.where((p) => p.id != id).toList();
    await saveAll(updated);
    await storageHelper.deleteProjectLabels(id);
  }

  /// 전체 프로젝트 삭제
  Future<void> deleteAll() async {
    await saveAll([]);
  }

  /// 프로젝트 가져오기 (외부 import용)
  Future<List<Project>> importFromExternal() async {
    return await storageHelper.loadProjectFromConfig('import');
  }

  /// 프로젝트 설정 내보내기 (json 저장 또는 다운로드 경로 반환)
  Future<String> exportConfig(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }
}
