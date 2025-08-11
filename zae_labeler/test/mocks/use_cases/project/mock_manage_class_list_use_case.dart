import 'package:zae_labeler/src/features/project/models/project_model.dart';
import 'package:zae_labeler/src/features/project/use_cases/manage_class_list_use_case.dart';

/// ManageClassListUseCase의 테스트용 모의 구현
/// 반환 타입을 Project?로 변경해 프로젝트가 없으면 null을 반환합니다.
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

  @override
  Future<Project?> addClass(String projectId, String newClass) async {
    addCalls.add('$projectId:$newClass');
    final project = _projects[projectId];
    if (project == null) {
      return null; // 프로젝트가 없으면 null
    }
    if (!project.classes.contains(newClass)) {
      final updatedProject = project.copyWith(classes: [...project.classes, newClass]);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project;
  }

  @override
  Future<Project?> removeClass(String projectId, int index) async {
    removeCalls.add('$projectId:$index');
    final project = _projects[projectId];
    if (project == null) {
      return null;
    }
    if (index >= 0 && index < project.classes.length) {
      final updatedClasses = List<String>.from(project.classes)..removeAt(index);
      final updatedProject = project.copyWith(classes: updatedClasses);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project; // 잘못된 인덱스면 원본 반환
  }

  @override
  Future<Project?> editClass(String projectId, int index, String newName) async {
    editCalls.add('$projectId:$index->$newName');
    final project = _projects[projectId];
    if (project == null) {
      return null;
    }
    if (index >= 0 && index < project.classes.length) {
      final updatedClasses = List<String>.from(project.classes)..[index] = newName;
      final updatedProject = project.copyWith(classes: updatedClasses);
      _projects[projectId] = updatedProject;
      return updatedProject;
    }
    return project; // 잘못된 인덱스면 원본 반환
  }
}
