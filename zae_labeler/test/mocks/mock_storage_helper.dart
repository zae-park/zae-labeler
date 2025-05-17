import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';

class MockStorageHelper implements StorageHelperInterface {
  final Map<String, Map<String, LabelModel>> _labelStorage = {}; // 📦 label 저장소
  List<Project> savedProjects = [];
  bool wasSaveProjectCalled = false;
  bool shouldThrowOnSave = false;

  @override
  Future<void> saveProjectConfig(List<Project> project) async {
    wasSaveProjectCalled = true;

    if (shouldThrowOnSave) {
      throw Exception('Failed to save');
    }

    savedProjects = project; // 단일 저장 후 리스트 유지
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String config) async {
    return savedProjects;
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    return '/mock/path/${project.name}_config.json';
  }

  @override
  Future<void> saveProjectList(List<Project> projects) async {}

  @override
  Future<List<Project>> loadProjectList() async => [];

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    _labelStorage[projectId] ??= {};
    _labelStorage[projectId]![dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    final projectMap = _labelStorage[projectId];
    final label = projectMap?[dataId];

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
        return MultiClassSegmentationLabelModel.empty(); // ✅ 올바른 타입 반환
      default:
        throw UnimplementedError("Mock for $mode not implemented.");
    }
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {}

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async => [];

  @override
  Future<void> deleteProjectLabels(String projectId) async {}

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async => '/mock/path/${project.name}_labels.zip';

  @override
  Future<List<LabelModel>> importAllLabels() async => [];

  @override
  Future<void> clearAllCache() async {}
}
