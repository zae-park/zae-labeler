// lib/src/utils/interface_storage_helper.dart
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

abstract class StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================
  Future<void> saveProjectConfig(List<Project> projects);
  Future<List<Project>> loadProjectFromConfig(String projectConfig);
  Future<String> downloadProjectConfig(Project project);

  // ==============================
  // 📌 **Project List Management**
  // ==============================
  Future<void> saveProjectList(List<Project> projects);
  Future<List<Project>> loadProjectList();

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel);
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode);

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels);
  Future<List<LabelModel>> loadAllLabels(String projectId);
  Future<void> deleteProjectLabels(String projectId);

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList);
  Future<List<LabelModel>> importAllLabels();

  // ==============================
  // 📌 **Cache Management**
  // ==============================
  Future<void> clearAllCache();
}

class LabelModelConverter {
  /// ✅ `LabelModel`을 JSON으로 변환하는 메서드
  static Map<String, dynamic> toJson(LabelModel model) {
    if (model is SingleClassificationLabelModel ||
        model is MultiClassificationLabelModel ||
        model is CrossClassificationLabelModel ||
        model is SingleClassSegmentationLabelModel ||
        model is MultiClassSegmentationLabelModel) {
      return model.toJson(); // ✅ 각 구현체의 toJson() 사용
    } else {
      throw UnimplementedError("toJson() not implemented for ${model.runtimeType}");
    }
  }

  /// ✅ JSON 데이터를 `LabelModel` 객체로 변환하는 메서드
  static LabelModel fromJson(LabelingMode mode, Map<String, dynamic> json) {
    try {
      switch (mode) {
        case LabelingMode.singleClassification:
          return SingleClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: json['label']);
        case LabelingMode.multiClassification:
          return MultiClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: Set<String>.from(json['label']));
        case LabelingMode.crossClassification:
          return CrossClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: json['label']);
        case LabelingMode.singleClassSegmentation:
          return SingleClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['label']));
        case LabelingMode.multiClassSegmentation:
          return MultiClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['label']));
      }
    } catch (e) {
      return SingleClassificationLabelModel.empty(); // 예외 발생 시 기본값 반환
    }
  }
}
