// lib/src/platform_helpers/storage/switchable_storage_helper.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'interface_storage_helper.dart';
import 'storage_helper_factory.dart'; // createLocalStorageHelper()
import 'cloud_storage_helper.dart'; // CloudStorageHelper

class SwitchableStorageHelper with ChangeNotifier implements StorageHelperInterface {
  StorageHelperInterface _delegate;

  SwitchableStorageHelper(StorageHelperInterface initial) : _delegate = initial;

  Future<void> switchToLocal() async {
    _delegate = createLocalStorageHelper();
    notifyListeners();
  }

  Future<void> switchToCloud() async {
    _delegate = CloudStorageHelper();
    notifyListeners();
  }

  // ↓↓↓ 모든 메서드를 _delegate로 그대로 위임하세요.
  @override
  Future<void> saveProjectConfig(List<Project> projects) => _delegate.saveProjectConfig(projects);

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) => _delegate.loadProjectFromConfig(projectConfig);

  @override
  Future<String> downloadProjectConfig(Project project) => _delegate.downloadProjectConfig(project);

  @override
  Future<void> saveProjectList(List<Project> projects) => _delegate.saveProjectList(projects);

  @override
  Future<List<Project>> loadProjectList() => _delegate.loadProjectList();

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) =>
      _delegate.saveLabelData(projectId, dataId, dataPath, labelModel);

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) =>
      _delegate.loadLabelData(projectId, dataId, dataPath, mode);

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) => _delegate.saveAllLabels(projectId, labels);

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) => _delegate.loadAllLabelModels(projectId);

  @override
  Future<void> deleteProjectLabels(String projectId) => _delegate.deleteProjectLabels(projectId);

  @override
  Future<void> deleteProject(String projectId) => _delegate.deleteProject(projectId);

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) =>
      _delegate.exportAllLabels(project, labelModels, fileDataList);

  @override
  Future<List<LabelModel>> importAllLabels() => _delegate.importAllLabels();

  @override
  Future<void> clearAllCache() => _delegate.clearAllCache();

  @override
  Future<Uint8List> readDataBytes(DataInfo info) {
    return _delegate.readDataBytes(info);
  }

  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) {
    return _delegate.ensureLocalObjectUrl(info);
  }

  @override
  Future<void> revokeLocalObjectUrl(String url) {
    return _delegate.revokeLocalObjectUrl(url);
  }

  @visibleForTesting
  Future<void> switchToForTest(StorageHelperInterface next) async {
    _delegate = next;
    notifyListeners();
  }
}
