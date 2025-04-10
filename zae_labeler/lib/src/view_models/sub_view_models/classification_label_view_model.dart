// 📁 sub_view_models/classification_label_view_model.dart

import 'base_label_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';

class ClassificationLabelViewModel extends LabelViewModel {
  ClassificationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
  });

  @override
  void updateLabel(dynamic labelData) {
    if (labelModel is ClassificationLabelModel) {
      if (labelData is String || labelData is List<String>) {
        labelModel = (labelModel as ClassificationLabelModel).updateLabel(labelData);
        notifyListeners();
      } else {
        throw ArgumentError('labelData must be String or List<String> for classification');
      }
    }
  }

  void toggleLabel(String labelItem) {
    if (labelModel is ClassificationLabelModel) {
      labelModel = (labelModel as ClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
    }
  }

  bool isLabelSelected(String labelItem) {
    return labelModel.isSelected(labelItem);
  }
}
