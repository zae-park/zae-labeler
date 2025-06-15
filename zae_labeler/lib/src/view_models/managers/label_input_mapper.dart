import '../../models/label_model.dart';
import '../../models/sub_models/classification_label_model.dart';

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
    if (labelData is! String) throw ArgumentError('Expected String');
    return CrossClassificationLabelModel(
      dataId: dataId,
      dataPath: dataPath,
      labeledAt: DateTime.now(),
      label: CrossDataPair(sourceId: '', targetId: '', relation: labelData),
    );
  }
}
