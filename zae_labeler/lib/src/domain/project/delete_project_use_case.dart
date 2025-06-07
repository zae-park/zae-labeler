import '../../repositories/project_repository.dart';

/// ✅ UseCase: 프로젝트 삭제 (단일 or 복수 ID 기준)
class DeleteProjectUseCase {
  final ProjectRepository repository;

  DeleteProjectUseCase({required this.repository});

  /// 🔹 단일 삭제
  Future<void> deleteById(String projectId) async {
    await repository.deleteById(projectId);
  }

  /// 🔹 복수 삭제 (라벨도 삭제)
  Future<void> deleteAll(List<String> projectIds) async {
    for (final id in projectIds) {
      await repository.deleteById(id); // ✅ 라벨도 함께 삭제됨
    }
  }
}
