import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';
import 'package:zae_labeler/src/repositories/project_repository.dart';
import 'mock_storage_helper.dart';

class MockProjectRepository implements ProjectRepository {
  List<Project> _projects = [];
  bool wasSaveProjectCalled = false;
  bool wasSaveAllCalled = false;
  bool wasDeleteCalled = false;
  bool wasLabelDeleted = false;

  @override
  final StorageHelperInterface storageHelper = MockStorageHelper();

  @override
  Future<List<Project>> fetchAllProjects() async => _projects;

  @override
  Future<Project?> findById(String id) async {
    return _projects.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<void> saveProject(Project project) async {
    wasSaveProjectCalled = true;
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _projects[idx] = project;
    } else {
      _projects.add(project);
    }
  }

  @override
  Future<void> saveAll(List<Project> list) async {
    wasSaveAllCalled = true;
    _projects = list;
  }

  @override
  Future<void> deleteById(String id) async {
    wasDeleteCalled = true;
    _projects.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> deleteAll() async {
    wasDeleteCalled = true;
    _projects.clear();
  }

  @override
  Future<List<Project>> importFromExternal() async {
    return _projects;
  }

  @override
  Future<String> exportConfig(Project project) async {
    return '/mock/path/${project.name}.json';
  }

  // @override
  // Future<void> deleteProjectLabels(String projectId) async {
  //   wasLabelDeleted = true;
  // }
}
