import '../models/label_model.dart';
import 'label_view_model.dart';
export 'sub_view_models/base_label_view_model.dart';
export 'sub_view_models/classification_label_view_model.dart';
export 'sub_view_models/segmentation_label_view_model.dart';

import '../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../repositories/label_repository.dart';

class LabelViewModelFactory {
  static LabelViewModel create({
    required String projectId,
    required String dataId,
    required String dataFilename,
    required String dataPath,
    required LabelingMode mode,
    required StorageHelperInterface storageHelper,
    required LabelRepository labelRepository,
  }) {
    final baseArgs = (
      projectId: projectId,
      dataId: dataId,
      dataFilename: dataFilename,
      dataPath: dataPath,
      mode: mode,
      storageHelper: storageHelper,
      labelRepository: labelRepository,
    );

    switch (mode) {
      case LabelingMode.singleClassification:
      case LabelingMode.multiClassification:
        return ClassificationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: baseArgs.storageHelper,
          labelRepository: baseArgs.labelRepository,
        );

      case LabelingMode.crossClassification:
        return CrossClassificationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: baseArgs.storageHelper,
          labelRepository: baseArgs.labelRepository,
        );

      case LabelingMode.singleClassSegmentation:
      case LabelingMode.multiClassSegmentation:
        return SegmentationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: baseArgs.storageHelper,
          labelRepository: baseArgs.labelRepository,
        );
    }
  }
}
