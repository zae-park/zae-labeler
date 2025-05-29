import '../../repositories/project_repository.dart';

/// ✅ UseCase: 프로젝트 삭제 (단일 or 전체)
class DeleteProjectUseCase {
  final ProjectRepository repository;

  DeleteProjectUseCase({required this.repository});

  /// 🔹 단일 프로젝트 삭제 (저장소 내부에서 삭제 처리)
  Future<void> deleteById(String projectId) async {
    await repository.deleteById(projectId);
  }

  /// 🔹 전체 프로젝트 리스트 저장 (외부에서 필터링 후 일괄 저장)
  Future<void> deleteAll(List<String> projectIds) async {
    final all = await repository.fetchAllProjects();
    final filtered = all.where((p) => !projectIds.contains(p.id)).toList();
    await repository.saveAll(filtered);
  }
}
