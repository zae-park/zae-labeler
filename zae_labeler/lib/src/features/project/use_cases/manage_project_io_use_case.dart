import '../models/project_model.dart';
import '../repository/project_repository.dart';
import '../../../core/use_cases/validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 IO (단일 or 복수 ID 기준)
class ManageProjectIOUseCase {
  final ProjectRepository repository;

  ManageProjectIOUseCase({required this.repository});

  /// 🔹 단일 저장
  Future<void> saveOne(Project project) async {
    ProjectValidator.validate(project);
    await repository.saveProject(project);
  }

  /// 🔹 전체 저장
  Future<void> saveAll(List<Project> projects) async {
    await repository.saveAll(projects);
  }

  /// 🔹 단일 삭제
  Future<void> deleteById(String projectId) async {
    await repository.deleteById(projectId);
  }

  /// 🔹 복수 삭제
  Future<void> deleteAll(List<String> projectIds) async {
    for (final id in projectIds) {
      await repository.deleteById(id);
    }
  }

  /// 🔹 전체 프로젝트 불러오기
  Future<List<Project>> fetchAll() async {
    return await repository.fetchAllProjects();
  }

  /// 🔹 캐시 초기화
  Future<void> clearCache() async {
    await repository.storageHelper.clearAllCache();
  }

  /// 🔹 외부에서 프로젝트들 가져오기
  Future<List<Project>> importProjects() async {
    return await repository.importFromExternal();
  }

  /// 🔹 프로젝트 설정 내보내기
  Future<String> exportProject(Project project) async {
    return await repository.exportConfig(project);
  }
}
