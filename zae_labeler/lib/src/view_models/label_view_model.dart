import 'package:flutter/foundation.dart';

import '../models/label_model.dart';
import '../domain/label/label_use_cases.dart';
import 'label_view_model.dart';
import 'managers/label_input_mapper.dart';
export 'sub_view_models/base_label_view_model.dart';
export 'sub_view_models/classification_label_view_model.dart';
export 'sub_view_models/segmentation_label_view_model.dart';

class LabelInputMapperFactory {
  static LabelInputMapper create(LabelingMode mode) {
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

class LabelViewModelFactory {
  static LabelViewModel create({
    required String projectId,
    required String dataId,
    required String dataFilename,
    required String dataPath,
    required LabelingMode mode,
    required LabelUseCases labelUseCases,
  }) {
    final baseArgs = (
      projectId: projectId,
      dataId: dataId,
      dataFilename: dataFilename,
      dataPath: dataPath,
      mode: mode,
      labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
      labelUseCases: labelUseCases,
      labelInputMapper: LabelInputMapperFactory.create(mode),
    );
    debugPrint("[Factory.create] mode=$mode");
    switch (mode) {
      case LabelingMode.singleClassification:
      case LabelingMode.multiClassification:
        return ClassificationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: baseArgs.labelModel,
          labelUseCases: baseArgs.labelUseCases,
          labelInputMapper: baseArgs.labelInputMapper,
        );

      case LabelingMode.crossClassification:
        return CrossClassificationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: baseArgs.labelModel,
          labelUseCases: baseArgs.labelUseCases,
          labelInputMapper: baseArgs.labelInputMapper,
        );

      case LabelingMode.singleClassSegmentation:
      case LabelingMode.multiClassSegmentation:
        return SegmentationLabelViewModel(
          projectId: baseArgs.projectId,
          dataId: baseArgs.dataId,
          dataFilename: baseArgs.dataFilename,
          dataPath: baseArgs.dataPath,
          mode: baseArgs.mode,
          labelModel: baseArgs.labelModel,
          labelUseCases: baseArgs.labelUseCases,
          labelInputMapper: baseArgs.labelInputMapper,
        );
    }
  }
}
