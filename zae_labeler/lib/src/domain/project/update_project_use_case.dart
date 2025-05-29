import '../../models/project_model.dart';
import '../../repositories/project_repository.dart';
import '../validator/project_validator.dart';

/// ✅ UseCase: 프로젝트 업데이트
/// - 기존 프로젝트를 갱신합니다 (ID 유지)
class UpdateProjectUseCase {
  final ProjectRepository repository;

  UpdateProjectUseCase({required this.repository});

  Future<void> call(Project updatedProject) async {
    if (updatedProject.id.isEmpty) {
      throw ArgumentError('프로젝트 ID가 없습니다.');
    }
    ProjectValidator.validate(updatedProject);
    await repository.saveProject(updatedProject);
  }
}
