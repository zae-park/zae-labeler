import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 불러오기
/// - 전체 목록 불러오기
/// - 특정 ID의 단일 프로젝트 조회
class LoadProjectsUseCase {
  final ProjectRepository repository;

  LoadProjectsUseCase({required this.repository});

  /// 🔹 전체 프로젝트 목록 불러오기
  Future<List<Project>> loadAll() async {
    return await repository.fetchAllProjects();
  }

  /// 🔹 특정 ID의 단일 프로젝트 불러오기
  Future<Project?> loadById(String projectId) async {
    final project = await repository.findById(projectId);
    if (project != null) {
      ProjectValidator.validate(project);
    }
    return project;
  }
}
