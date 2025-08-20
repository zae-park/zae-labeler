// lib/src/features/label/logic/label_input_mapper.dart
import '../models/label_model.dart';
import '../models/sub_models/classification_label_model.dart';
import '../models/sub_models/segmentation_label_model.dart';

/// [labelData] 기대 타입 요약:
/// - SingleClassification: String? (null 허용)
/// - MultiClassification: Iterable<String> (List/Set 모두 허용)
/// - CrossClassification: CrossDataPair
/// - Segmentation: SegmentationData
abstract class LabelInputMapper {
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath});

  /// ✅ 모드별 매퍼 팩토리
  static LabelInputMapper forMode(LabelingMode mode) {
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationInputMapper();
      case LabelingMode.multiClassification:
        return MultiClassificationInputMapper();
      case LabelingMode.crossClassification:
        return CrossClassificationInputMapper();
      case LabelingMode.singleClassSegmentation:
        return SingleSegmentationInputMapper();
      case LabelingMode.multiClassSegmentation:
        return MultiSegmentationInputMapper();
    }
  }
}

class SingleClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData != null && labelData is! String) {
      throw ArgumentError('Expected String or null for SingleClassification');
    }
    return SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData as String?);
  }
}

class MultiClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! Iterable<String>) {
      throw ArgumentError('Expected Iterable<String> for MultiClassification');
    }
    final set = labelData is Set<String> ? labelData : Set<String>.from(labelData);
    return MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: set);
  }
}

class CrossClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! CrossDataPair) {
      throw ArgumentError('Expected CrossDataPair for CrossClassification');
    }
    return CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

/// ✅ Single-Class Segmentation
class SingleSegmentationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! SegmentationData) {
      throw ArgumentError('Expected SegmentationData for Single Segmentation');
    }
    return SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

/// ✅ Multi-Class Segmentation
class MultiSegmentationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! SegmentationData) {
      throw ArgumentError('Expected SegmentationData for Multi Segmentation');
    }
    return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}
