import '../../../core/models/project_model.dart';
import '../../../core/models/label_model.dart';
import '../repository/project_repository.dart';

class EditProjectMetaUseCase {
  final ProjectRepository repository;

  EditProjectMetaUseCase({required this.repository});

  /// 프로젝트 이름 변경 및 저장된 최신 Project 반환
  Future<Project?> rename(String projectId, String newName) async {
    final project = await repository.findById(projectId);
    if (project != null) {
      project.updateName(newName);
      await repository.saveProject(project);
    }
    return project;
  }

  /// 라벨링 모드 변경 + 라벨 초기화 + 저장된 최신 Project 반환
  Future<Project?> changeLabelingMode(String projectId, LabelingMode newMode) async {
    final project = await repository.findById(projectId);
    if (project != null) {
      await repository.clearLabels(projectId);
      project.updateMode(newMode);
      await repository.saveProject(project);
    }
    return project;
  }

  /// 프로젝트의 모든 라벨 초기화 (상태 변경은 반환하지 않음)
  Future<void> clearLabels(String projectId) async {
    await repository.clearLabels(projectId);
  }
}
