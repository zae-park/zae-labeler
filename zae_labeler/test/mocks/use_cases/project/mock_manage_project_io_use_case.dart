import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/features/project/use_cases/manage_project_io_use_case.dart';

class MockManageProjectIOUseCase extends ManageProjectIOUseCase {
  List<Project> savedProjects = [];
  List<String> deletedIds = [];
  List<Project> importedProjects = [];
  String exportedPath = '';
  bool wasClearCacheCalled = false;

  MockManageProjectIOUseCase({required super.repository});

  @override
  Future<void> saveOne(Project project) async => await repository.saveProject(project);

  @override
  Future<void> saveAll(List<Project> projects) async => await repository.saveAll(projects);

  @override
  Future<void> deleteById(String projectId) async => await repository.deleteById(projectId);

  @override
  Future<void> deleteAll(List<String> projectIds) async {
    for (final id in projectIds) {
      await repository.deleteById(id);
    }
  }

  @override
  Future<List<Project>> fetchAll() async => await repository.fetchAllProjects();

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
