// 📁 sub_view_models/classification_label_view_model.dart

import 'package:flutter/material.dart';
import 'base_label_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../repositories/label_repository.dart';

/// ViewModel for single and multi classification labeling
class ClassificationLabelViewModel extends LabelViewModel {
  final LabelRepository labelRepository;

  ClassificationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.storageHelper,
    required this.labelRepository,
  });

  @override
  void updateLabel(dynamic labelData) {
    if (labelModel is ClassificationLabelModel) {
      if (labelData is String || labelData is List<String>) {
        debugPrint("[ClsLabelVM.updateLabel] labelModel: $labelModel");
        labelModel.updateLabel(labelData);
        notifyListeners();
      } else {
        throw ArgumentError('labelData must be String or List<String> for classification');
      }
    }
  }

  void toggleLabel(String labelItem) {
    debugPrint("[ClsLabelVM.toggleLabel] labelModel: $labelModel");
    if (labelModel is ClassificationLabelModel) {
      labelModel = (labelModel as ClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
    }
  }

  bool isLabelSelected(String labelItem) {
    if (labelModel is ClassificationLabelModel) {
      return (labelModel as ClassificationLabelModel).isSelected(labelItem);
    }
    return false;
  }

  @override
  Future<void> loadLabel() async {
    labelModel = await labelRepository.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    notifyListeners();
  }

  @override
  Future<void> saveLabel() async {
    await labelRepository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
  }
}

/// ViewModel for labeling data pairs (nC2 cross classification)
class CrossClassificationLabelViewModel extends LabelViewModel {
  final LabelRepository labelRepository;

  CrossClassificationLabelViewModel({
    required super.projectId,
    required super.dataId,
    required super.dataFilename,
    required super.dataPath,
    required super.mode,
    required super.labelModel,
    required super.storageHelper,
    required this.labelRepository,
  });

  @override
  void updateLabel(dynamic labelData) {
    if (labelModel is CrossClassificationLabelModel) {
      if (labelData is String) {
        labelModel = (labelModel as CrossClassificationLabelModel).updateLabel(
          (labelModel as CrossClassificationLabelModel).label!.copyWith(relation: labelData),
        );
        notifyListeners();
      } else {
        throw ArgumentError('labelData must be String for CrossClassification');
      }
    }
  }

  void toggleLabel(String labelItem) {
    if (labelModel is CrossClassificationLabelModel) {
      labelModel = (labelModel as CrossClassificationLabelModel).toggleLabel(labelItem);
      notifyListeners();
    }
  }

  bool isLabelSelected(String labelItem) {
    if (labelModel is CrossClassificationLabelModel) {
      return (labelModel as CrossClassificationLabelModel).isSelected(labelItem);
    }
    return false;
  }

  @override
  Future<void> loadLabel() async {
    labelModel = await labelRepository.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    notifyListeners();
  }

  @override
  Future<void> saveLabel() async {
    await labelRepository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
  }
}
