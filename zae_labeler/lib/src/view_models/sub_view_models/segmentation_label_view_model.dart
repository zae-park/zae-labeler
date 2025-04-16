// 📁 sub_view_models/segmentation_label_view_model

import 'base_label_view_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

class SegmentationLabelViewModel extends LabelViewModel {
  SegmentationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.storageHelper,
  });

  @override
  void updateLabel(dynamic labelData) {
    if (labelData is SegmentationData) {
      labelModel = labelModel.updateLabel(labelData);
      notifyListeners();
    } else {
      throw ArgumentError('labelData must be SegmentationData for segmentation');
    }
  }

  void addPixel(int x, int y, String classLabel) {
    if (labelModel is SegmentationLabelModel) {
      final updated = (labelModel as MultiClassSegmentationLabelModel).addPixel(x, y, classLabel);
      labelModel = updated;
      notifyListeners();
    }
  }

  void removePixel(int x, int y) {
    if (labelModel is MultiClassSegmentationLabelModel) {
      final updated = (labelModel as MultiClassSegmentationLabelModel).removePixel(x, y);
      labelModel = updated;
      notifyListeners();
    }
  }
}
