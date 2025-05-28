import '../../models/project_model.dart';
import '../validator/project_validator.dart';
import 'save_project_use_case.dart';

/// ✅ UseCase: 프로젝트 업데이트
/// - 기존 프로젝트를 갱신합니다 (ID 유지)
class UpdateProjectUseCase {
  final SaveProjectUseCase saveProjectUseCase;

  UpdateProjectUseCase({required this.saveProjectUseCase});

  Future<void> call(Project updatedProject) async {
    if (updatedProject.id.isEmpty) {
      throw ArgumentError('프로젝트 ID가 없습니다.');
    }
    ProjectValidator.validate(updatedProject);
    await saveProjectUseCase.saveOne(updatedProject);
  }
}
