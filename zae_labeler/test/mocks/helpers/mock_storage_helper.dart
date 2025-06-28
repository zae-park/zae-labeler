import 'package:zae_labeler/src/core/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/core/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';

class MockStorageHelper implements StorageHelperInterface {
  final Map<String, Map<String, LabelModel>> _labelStorage = {}; // 📦 label 저장소
  List<Project> savedProjects = [];
  Project? mockImportedProject;

  bool wasSaveProjectCalled = false;
  bool wasClearCacheCalled = false;
  bool shouldThrowOnSave = false;

  @override
  Future<void> saveProjectConfig(List<Project> project) async {
    wasSaveProjectCalled = true;
    if (shouldThrowOnSave) throw Exception('Failed to save');
    savedProjects = [...project];
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String config) async {
    if (mockImportedProject != null) {
      return [mockImportedProject!]; // 단일 Project → List<Project>로 래핑해서 넘김
    }
    return [];
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    return '/mock/path/${project.name}_config.json';
  }

  @override
  Future<void> saveProjectList(List<Project> projects) async {
    wasSaveProjectCalled = true;
    if (shouldThrowOnSave) throw Exception('Failed to save');
    savedProjects = [...projects];
  }

  @override
  Future<List<Project>> loadProjectList() async {
    return [...savedProjects];
  }

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    _labelStorage[projectId] ??= {};
    _labelStorage[projectId]![dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final label = _labelStorage[projectId]?[dataId];
    if (label != null) return label;

    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel.empty();
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel.empty();
      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel.empty();
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel.empty();
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel.empty();
    }
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    _labelStorage[projectId] = {for (var label in labels) label.dataId: label};
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async => _labelStorage[projectId]?.values.toList() ?? [];

  @override
  Future<void> deleteProjectLabels(String projectId) async {}

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) async => '/mock/path/${project.name}_labels.zip';

  @override
  Future<List<LabelModel>> importAllLabels() async => [];

  @override
  Future<void> clearAllCache() async {
    wasClearCacheCalled = true;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _labelStorage.remove(projectId);
    savedProjects.removeWhere((p) => p.id == projectId);
  }
}
