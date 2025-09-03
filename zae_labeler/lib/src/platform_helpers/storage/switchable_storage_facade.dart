import 'dart:typed_data';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';
import 'package:zae_labeler/src/platform_helpers/storage/switchable_storage_helper.dart';

/// 비-리스너블 래퍼: SwitchableStorageHelper를 StorageHelperInterface로 노출.
/// Provider가 Listenable 타입을 경고 없이 다루도록 안전하게 감싸줍니다.
class SwitchableStorageFacade implements StorageHelperInterface {
  final SwitchableStorageHelper _inner;
  SwitchableStorageFacade(this._inner);

  @override
  Future<void> saveProjectConfig(List<Project> projects) => _inner.saveProjectConfig(projects);

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) => _inner.loadProjectFromConfig(projectConfig);

  @override
  Future<String> downloadProjectConfig(Project project) => _inner.downloadProjectConfig(project);

  @override
  Future<void> saveProjectList(List<Project> projects) => _inner.saveProjectList(projects);

  @override
  Future<List<Project>> loadProjectList() => _inner.loadProjectList();

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) =>
      _inner.saveLabelData(projectId, dataId, dataPath, labelModel);

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) =>
      _inner.loadLabelData(projectId, dataId, dataPath, mode);

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) => _inner.saveAllLabels(projectId, labels);

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) => _inner.loadAllLabelModels(projectId);

  @override
  Future<void> deleteProjectLabels(String projectId) => _inner.deleteProjectLabels(projectId);

  @override
  Future<void> deleteProject(String projectId) => _inner.deleteProject(projectId);

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) =>
      _inner.exportAllLabels(project, labelModels, fileDataList);

  @override
  Future<List<LabelModel>> importAllLabels() => _inner.importAllLabels();

  @override
  Future<Uint8List> readDataBytes(DataInfo info) => _inner.readDataBytes(info);

  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) => _inner.ensureLocalObjectUrl(info);

  @override
  Future<void> revokeLocalObjectUrl(String url) => _inner.revokeLocalObjectUrl(url);

  @override
  Future<void> clearAllCache() => _inner.clearAllCache();

  @override
  Future<String> uploadText(String objectKey, String text, {String? contentType}) => _inner.uploadText(objectKey, text, contentType: contentType);
  @override
  Future<String> uploadBase64(String objectKey, String rawBase64, {String? contentType}) => _inner.uploadBase64(objectKey, rawBase64, contentType: contentType);
  @override
  Future<String> uploadBytes(String objectKey, Uint8List bytes, {String? contentType}) => _inner.uploadBytes(objectKey, bytes, contentType: contentType);

  // Project Upload delegation
  @override
  Future<String> uploadProjectText(String projectId, String objectKey, String text, {String? contentType}) =>
      _inner.uploadProjectText(projectId, objectKey, text, contentType: contentType);
  @override
  Future<String> uploadProjectBase64(String projectId, String objectKey, String rawBase64, {String? contentType}) =>
      _inner.uploadProjectBase64(projectId, objectKey, rawBase64, contentType: contentType);
  @override
  Future<String> uploadProjectBytes(String projectId, String objectKey, Uint8List bytes, {String? contentType}) =>
      _inner.uploadProjectBytes(projectId, objectKey, bytes, contentType: contentType);
}
