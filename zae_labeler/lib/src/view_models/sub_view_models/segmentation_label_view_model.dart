// 📁 sub_view_models/segmentation_label_view_model

import 'base_label_view_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';
import '../../repositories/label_repository.dart';

/// ViewModel for segmentation labeling.
/// Handles pixel-level updates and repository-backed I/O.
class SegmentationLabelViewModel extends LabelViewModel {
  final LabelRepository labelRepository;

  SegmentationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.storageHelper,
    required this.labelRepository,
  });

  /// Updates the entire segmentation label with a new label object.
  @override
  void updateLabel(dynamic labelData) {
    if (labelData is SegmentationData) {
      labelModel = labelModel.updateLabel(labelData);
      notifyListeners();
    } else {
      throw ArgumentError('labelData must be SegmentationData for segmentation');
    }
  }

  /// Adds a pixel at (x, y) for the given classLabel.
  void addPixel(int x, int y, String classLabel) {
    if (labelModel is MultiClassSegmentationLabelModel) {
      final updated = (labelModel as MultiClassSegmentationLabelModel).addPixel(x, y, classLabel);
      labelModel = updated;
      notifyListeners();
    }
  }

  /// Removes a pixel at (x, y).
  void removePixel(int x, int y) {
    if (labelModel is MultiClassSegmentationLabelModel) {
      final updated = (labelModel as MultiClassSegmentationLabelModel).removePixel(x, y);
      labelModel = updated;
      notifyListeners();
    }
  }

  /// Loads a segmentation label from the repository.
  @override
  Future<void> loadLabel() async {
    labelModel = await labelRepository.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    notifyListeners();
  }

  /// Saves the current segmentation label to the repository.
  @override
  Future<void> saveLabel() async {
    await labelRepository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
  }
}
