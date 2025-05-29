import '../../repositories/project_repository.dart';

/// ✅ UseCase: 프로젝트 삭제 (단일 or 복수 ID 기준)
class DeleteProjectUseCase {
  final ProjectRepository repository;

  DeleteProjectUseCase({required this.repository});

  /// 🔹 단일 프로젝트 삭제
  Future<void> deleteById(String projectId) async {
    await repository.deleteById(projectId);
  }

  /// 🔹 복수 ID 기준 프로젝트 삭제
  Future<void> deleteAll(List<String> projectIds) async {
    final all = await repository.fetchAllProjects();
    final filtered = all.where((p) => !projectIds.contains(p.id)).toList();
    await repository.saveAll(filtered);
  }
}
