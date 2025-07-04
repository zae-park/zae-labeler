import '../../features/label/models/label_model.dart';
import '../../features/label/models/sub_models/classification_label_model.dart';
import '../../features/label/models/sub_models/segmentation_label_model.dart';

/// [labelData]는 모드에 따라 다음과 같은 타입이 요구됩니다:
/// - SingleClassification: String
/// - MultiClassification: Set<String>
/// - CrossClassification: CrossDataPair
/// - Segmentation: SegmentationData
abstract class LabelInputMapper {
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath});
}

class SingleClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData != null && labelData is! String) {
      throw ArgumentError('Expected String or null');
    }
    return SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

class MultiClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! Set<String>) {
      throw ArgumentError('Expected Set<String>');
    }
    return MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

class CrossClassificationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! CrossDataPair) {
      throw ArgumentError('Expected CrossDataPair');
    }

    return CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

/// ✅ Single-Class Segmentation 용
class SingleSegmentationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! SegmentationData) {
      throw ArgumentError('Expected SegmentationData');
    }
    return SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}

/// ✅ Multi-Class Segmentation 용
class MultiSegmentationInputMapper extends LabelInputMapper {
  @override
  LabelModel map(dynamic labelData, {required String dataId, required String dataPath}) {
    if (labelData is! SegmentationData) {
      throw ArgumentError('Expected SegmentationData');
    }
    return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
  }
}
