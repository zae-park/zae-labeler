// 📁 sub_view_models/segmentation_label_view_model

import 'base_label_view_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

/// ViewModel for segmentation labeling.
/// Handles pixel-level updates and repository-backed I/O.
class SegmentationLabelViewModel extends LabelViewModel {
  SegmentationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.labelUseCases,
  });

  @override
  void updateLabel(dynamic labelData) {
    if (labelModel is SegmentationLabelModel) {
      if (labelData is SegmentationData) {
        labelModel = (labelModel as SegmentationLabelModel).copyWith(label: labelData);
        notifyListeners();
      } else {
        throw ArgumentError('labelData must be SegmentationLabelData');
      }
    }
  }

  @override
  Future<void> addPixel(int x, int y, String classLabel) async {
    final prev = labelModel as SegmentationLabelModel;
    final newModel = prev.copyWith(labeledAt: DateTime.now(), label: prev.label?.addPixel(x, y, classLabel));

    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  @override
  Future<void> removePixel(int x, int y) async {
    final prev = labelModel as SegmentationLabelModel;
    final newModel = prev.copyWith(labeledAt: DateTime.now(), label: prev.label?.removePixel(x, y));

    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }
}
