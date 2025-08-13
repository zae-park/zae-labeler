// test/mocks/repositories/mock_project_repository.dart
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/project/repository/project_repository.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';
import 'package:zae_labeler/src/core/models/data/data_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';

import '../helpers/mock_storage_helper.dart';

class MockProjectRepository extends ProjectRepository {
  final Map<String, Project> _mockStore = {};
  bool wasSaveCalled = false;
  bool wasClearLabelsCalled = false; // ✅ 추가
  bool wasDownloadCalled = false; // ✅ 추가

  MockProjectRepository({StorageHelperInterface? storageHelper}) : super(storageHelper: storageHelper ?? MockStorageHelper());

  @override
  Future<List<Project>> fetchAllProjects() async {
    return _mockStore.values.toList();
  }

  @override
  Future<Project?> findById(String id) async {
    return _mockStore[id];
  }

  @override
  Future<void> saveProject(Project project) async {
    _mockStore[project.id] = project;
    wasSaveCalled = true;
  }

  @override
  Future<void> saveAll(List<Project> list) async {
    _mockStore.clear();
    for (var project in list) {
      _mockStore[project.id] = project;
    }
  }

  @override
  Future<void> deleteById(String id) async {
    _mockStore.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _mockStore.clear();
  }

  @override
  Future<void> clearLabels(String projectId) async {
    wasClearLabelsCalled = true;
  }

  @override
  Future<Project?> updateProjectMode(String id, LabelingMode newMode) async {
    final project = _mockStore[id];
    if (project != null) {
      project.updateMode(newMode);
      await saveProject(project);
    }
    return project;
  }

  @override
  Future<void> updateProjectClasses(String id, List<String> newClasses) async {
    final project = _mockStore[id];
    if (project != null) {
      project.updateClasses(newClasses);
      await saveProject(project);
    }
  }

  @override
  Future<Project?> updateProjectName(String id, String newName) async {
    final project = _mockStore[id];
    if (project != null) {
      project.updateName(newName);
      await saveProject(project);
    }
    return project;
  }

  @override
  Future<void> updateDataInfos(String id, List<DataInfo> newDataInfos) async {
    final project = _mockStore[id];
    if (project != null) {
      project.updateDataInfos(newDataInfos);
      await saveProject(project);
    }
  }

  @override
  Future<void> addDataInfo(String id, DataInfo newDataInfo) async {
    final project = _mockStore[id];
    if (project != null) {
      project.addDataInfo(newDataInfo);
      await saveProject(project);
    }
  }

  @override
  Future<void> removeDataInfoById(String id, String dataInfoId) async {
    final project = _mockStore[id];
    if (project != null) {
      project.removeDataInfoById(dataInfoId);
      await saveProject(project);
    }
  }

  @override
  Future<List<Project>> importFromExternal() async {
    return _mockStore.values.toList();
  }

  @override
  Future<String> exportConfig(Project project) async {
    wasDownloadCalled = true;
    return 'mock_config_path.json';
  }
}
