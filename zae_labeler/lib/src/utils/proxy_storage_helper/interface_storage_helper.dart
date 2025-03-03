// lib/src/utils/interface_storage_helper.dart
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../models/label_models/classification_label_model.dart';
import '../../models/label_models/segmentation_label_model.dart';

abstract class StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================
  Future<void> saveProjectConfig(List<Project> projects);
  Future<List<Project>> loadProjectFromConfig(String projectConfig);
  Future<String> downloadProjectConfig(Project project);

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel);
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode);

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels);
  Future<List<LabelModel>> loadAllLabels(String projectId);

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList);
  Future<List<LabelModel>> importAllLabels();
}

class LabelModelConverter {
  /// ✅ `LabelModel`을 JSON으로 변환하는 메서드
  static Map<String, dynamic> toJson(LabelModel labelModel) {
    if (labelModel is SingleClassificationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'label': labelModel.label};
    } else if (labelModel is MultiClassificationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'labels': labelModel.label};
    } else if (labelModel is SingleClassSegmentationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'segmentation': labelModel.label.toJson()};
    } else if (labelModel is MultiClassSegmentationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'segmentation': labelModel.label.toJson()};
    }
    throw Exception("Unknown LabelModel type");
  }

  /// ✅ JSON 데이터를 `LabelModel` 객체로 변환하는 메서드
  static LabelModel fromJson(LabelingMode mode, Map<String, dynamic> json) {
    try {
      switch (mode) {
        case LabelingMode.singleClassification:
          return SingleClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: json['label']);
        case LabelingMode.multiClassification:
          return MultiClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: List<String>.from(json['labels']));
        case LabelingMode.singleClassSegmentation:
          return SingleClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['segmentation']));
        case LabelingMode.multiClassSegmentation:
          return MultiClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['segmentation']));
      }
    } catch (e) {
      return SingleClassificationLabelModel.empty(); // 예외 발생 시 기본값 반환
    }
  }
}
