// 📁 create_project_use_case.dart
import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';
import '../validator/project_validator.dart';

class CreateProjectUseCase {
  final ProjectRepository repository;

  CreateProjectUseCase({required this.repository});

  Future<void> call(Project project) async {
    ProjectValidator.validate(project);
    await repository.saveProject(project);
  }
}
