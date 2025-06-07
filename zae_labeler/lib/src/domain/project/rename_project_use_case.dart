// 📁 Rename project
import '../../repositories/project_repository.dart';

class RenameProjectUseCase {
  final ProjectRepository repository;

  RenameProjectUseCase({required this.repository});

  Future<void> call(String projectId, String newName) async {
    await repository.updateProjectName(projectId, newName);
  }
}
