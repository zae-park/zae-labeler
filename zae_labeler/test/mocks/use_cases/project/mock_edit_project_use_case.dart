import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/features/project/use_cases/edit_project_meta_use_case.dart';

class MockEditProjectMetaUseCase extends EditProjectMetaUseCase {
  final Map<String, Project> _projects = {};
  List<String> renamedProjectIds = [];
  List<String> modeChangedProjectIds = [];
  List<String> clearedLabelProjectIds = [];

  MockEditProjectMetaUseCase({required super.repository});

  void seedProject(Project project) {
    _projects[project.id] = project;
  }

  Project? getProject(String id) => _projects[id];

  @override
  Future<Project?> rename(String projectId, String newName) async {
    renamedProjectIds.add(projectId);
    final project = _projects[projectId];
    if (project != null) {
      final updated = project.copyWith(name: newName);
      _projects[projectId] = updated;
      return updated;
    }
    return null;
  }

  @override
  Future<Project?> changeLabelingMode(String projectId, LabelingMode newMode) async {
    modeChangedProjectIds.add(projectId);
    final project = _projects[projectId];
    if (project != null) {
      final updated = project.copyWith(mode: newMode);
      _projects[projectId] = updated;
      return updated;
    }
    return null;
  }

  @override
  Future<void> clearLabels(String projectId) async {
    clearedLabelProjectIds.add(projectId);
    // 라벨 자체는 저장하지 않으므로 추적만
  }
}
