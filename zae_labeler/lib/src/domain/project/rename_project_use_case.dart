// 📁 Rename project
import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';

class RenameProjectUseCase {
  final ProjectRepository repository;

  RenameProjectUseCase({required this.repository});

  Future<Project?> call(String projectId, String newName) async {
    return await repository.updateProjectName(projectId, newName);
  }
}
