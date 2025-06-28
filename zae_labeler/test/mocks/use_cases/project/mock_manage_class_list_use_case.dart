import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/core/use_cases/project/manage_class_list_use_case.dart';

class MockManageClassListUseCase extends ManageClassListUseCase {
  final Map<String, Project> _projects = {};
  List<String> addCalls = [];
  List<String> removeCalls = [];
  List<String> editCalls = [];

  MockManageClassListUseCase({required super.repository});

  void seedProject(Project project) {
    _projects[project.id] = project;
  }

  Project? getProject(String id) => _projects[id];

  Project _getProjectOrThrow(String projectId) {
    final project = _projects[projectId];
    if (project == null) {
      throw StateError("Project not found for id: $projectId");
    }
    return project;
  }

  @override
  Future<Project> addClass(String projectId, String newClass) async {
    addCalls.add('$projectId:$newClass');
    final project = _getProjectOrThrow(projectId);
    if (!project.classes.contains(newClass)) {
      final updatedProject = project.copyWith(classes: [...project.classes, newClass]);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project;
  }

  @override
  Future<Project> removeClass(String projectId, int index) async {
    removeCalls.add('$projectId:$index');
    final project = _getProjectOrThrow(projectId);
    if (index >= 0 && index < project.classes.length) {
      final updatedClasses = List<String>.from(project.classes)..removeAt(index);
      final updatedProject = project.copyWith(classes: updatedClasses);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project;
  }

  @override
  Future<Project> editClass(String projectId, int index, String newName) async {
    editCalls.add('$projectId:$index->$newName');
    final project = _getProjectOrThrow(projectId);
    if (index >= 0 && index < project.classes.length) {
      final updatedClasses = List<String>.from(project.classes)..[index] = newName;
      final updatedProject = project.copyWith(classes: updatedClasses);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project;
  }
}
