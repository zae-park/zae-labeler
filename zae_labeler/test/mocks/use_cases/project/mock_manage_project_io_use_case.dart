import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/domain/project/manage_project_io_use_case.dart';

class MockManageProjectIOUseCase extends ManageProjectIOUseCase {
  List<Project> savedProjects = [];
  List<String> deletedIds = [];
  List<Project> importedProjects = [];
  String exportedPath = '';
  bool wasClearCacheCalled = false;

  MockManageProjectIOUseCase({required super.repository});

  @override
  Future<void> saveOne(Project project) async {
    savedProjects.removeWhere((p) => p.id == project.id);
    savedProjects.add(project);
  }

  @override
  Future<void> saveAll(List<Project> projects) async {
    savedProjects = projects;
  }

  @override
  Future<void> deleteById(String projectId) async {
    deletedIds.add(projectId);
    savedProjects.removeWhere((p) => p.id == projectId);
  }

  @override
  Future<void> deleteAll(List<String> projectIds) async {
    deletedIds.addAll(projectIds);
    savedProjects.removeWhere((p) => projectIds.contains(p.id));
  }

  @override
  Future<List<Project>> fetchAll() async {
    return savedProjects;
  }

  @override
  Future<void> clearCache() async {
    wasClearCacheCalled = true;
  }

  @override
  Future<List<Project>> importProjects() async {
    return importedProjects;
  }

  @override
  Future<String> exportProject(Project project) async {
    exportedPath = '/mock/export/${project.id}.json';
    return exportedPath;
  }
}
