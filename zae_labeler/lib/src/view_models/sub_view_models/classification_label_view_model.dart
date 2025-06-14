// 📁 sub_view_models/classification_label_view_model.dart

import 'package:flutter/material.dart';
import 'base_label_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';

/// ViewModel for single and multi classification labeling
class ClassificationLabelViewModel extends LabelViewModel {
  ClassificationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.labelUseCases,
  });

  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (labelModel is ClassificationLabelModel) {
      if (labelData is String || labelData is List<String>) {
        debugPrint("[ClsLabelVM.updateLabel] labelModel: $labelModel");
        labelModel.updateLabel(labelData);
        notifyListeners();
        await labelUseCases.single.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
      } else {
        throw ArgumentError('labelData must be String or List<String> for classification');
      }
    }
  }

  Future<void> toggleLabel(String labelItem) async {
    debugPrint("[ClsLabelVM.toggleLabel] labelModel: $labelModel");
    if (labelModel is ClassificationLabelModel) {
      labelModel = (labelModel as ClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
      await labelUseCases.single.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
    }
  }

  bool isLabelSelected(String labelItem) {
    if (labelModel is ClassificationLabelModel) {
      return (labelModel as ClassificationLabelModel).isSelected(labelItem);
    }
    return false;
  }
}

/// ViewModel for labeling data pairs (nC2 cross classification)
class CrossClassificationLabelViewModel extends LabelViewModel {
  CrossClassificationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.labelUseCases,
  });

  @override
  Future<void> updateLabel(dynamic labelData) async {
    if (labelModel is CrossClassificationLabelModel) {
      if (labelData is String) {
        labelModel = (labelModel as CrossClassificationLabelModel).updateLabel(
          (labelModel as CrossClassificationLabelModel).label!.copyWith(relation: labelData),
        );
        notifyListeners();
        await labelUseCases.single.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
      } else {
        throw ArgumentError('labelData must be String for CrossClassification');
      }
    }
  }

  Future<void> toggleLabel(String labelItem) async {
    if (labelModel is CrossClassificationLabelModel) {
      labelModel = (labelModel as CrossClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
      await labelUseCases.single.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
    }
  }

  bool isLabelSelected(String labelItem) {
    if (labelModel is CrossClassificationLabelModel) {
      return (labelModel as CrossClassificationLabelModel).isSelected(labelItem);
    }
    return false;
  }
}
