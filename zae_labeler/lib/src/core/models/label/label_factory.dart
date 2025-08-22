// core/models/label/label_factory.dart

import 'label_types.dart';
import 'base_label_model.dart';
import 'classification_label_model.dart';
import 'segmentation_label_model.dart';

/// LabelModelFactory
/// - 새 라벨 인스턴스 생성(프로젝트 모드 기준)
abstract class LabelModelFactory {
  static LabelModel createNew(LabelingMode mode, {required String dataId}) {
    final now = DateTime.now();
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel(dataId: dataId, labeledAt: now, label: null);
    }
  }

  static Type expectedType(LabelingMode mode) {
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel;
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel;
      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel;
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel;
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel;
    }
  }
}
