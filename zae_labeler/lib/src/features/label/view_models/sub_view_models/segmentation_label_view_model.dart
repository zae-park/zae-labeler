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
    required super.labelInputMapper,
  });

  @override
  Future<void> addPixel(int x, int y, String classLabel) async {
    final prev = labelModel as SegmentationLabelModel;
    final updated = prev.label?.addPixel(x, y, classLabel);
    final newModel = prev.copyWith(labeledAt: DateTime.now(), label: updated);
    await updateLabel(newModel);
  }

  @override
  Future<void> removePixel(int x, int y) async {
    final prev = labelModel as SegmentationLabelModel;
    final updated = prev.label?.removePixel(x, y);
    final newModel = prev.copyWith(labeledAt: DateTime.now(), label: updated);
    await updateLabel(newModel);
  }
}
