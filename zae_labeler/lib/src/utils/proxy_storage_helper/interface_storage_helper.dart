// lib/src/utils/interface_storage_helper.dart
import 'package:flutter/foundation.dart';

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
  Future<List<LabelModel>> loadAllLabelModels(String projectId);
  Future<void> deleteProjectLabels(String projectId);
  Future<void> deleteProject(String projectId);

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList);
  Future<List<LabelModel>> importAllLabels();

  // ==============================
  // 📌 **Cache Management**
  // ==============================
  Future<void> clearAllCache();
}

class LabelModelConverter {
  /// ✅ `LabelModel`을 JSON으로 변환하는 메서드
  static Map<String, dynamic> toJson(LabelModel model) => model.toJson();

  /// ✅ JSON 데이터를 `LabelModel` 객체로 변환하는 메서드
  static LabelModel fromJson(LabelingMode mode, Map<String, dynamic> json) {
    try {
      final dataId = json['data_id'] ?? '';
      final dataPath = json['data_path'];
      final labeledAt = DateTime.parse(json['labeled_at']);
      debugPrint("[LabelModelConverter.fromJson] 📥 LabelModel 생성: $mode / $dataId");

      switch (mode) {
        case LabelingMode.singleClassification:
          return SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: json['label'], labeledAt: labeledAt);
        case LabelingMode.multiClassification:
          return MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: Set<String>.from(json['label']), labeledAt: labeledAt);
        case LabelingMode.crossClassification:
          return CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: CrossDataPair.fromJson(json), labeledAt: labeledAt);
        case LabelingMode.singleClassSegmentation:
          return SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: SegmentationData.fromJson(json['label']), labeledAt: labeledAt);
        case LabelingMode.multiClassSegmentation:
          return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: SegmentationData.fromJson(json['label']), labeledAt: labeledAt);
      }
    } catch (e) {
      debugPrint("[LabelModelConverter.fromJson] ❌ LabelModel 생성 실패: $e");
      return SingleClassificationLabelModel.empty();
    }
  }
}
