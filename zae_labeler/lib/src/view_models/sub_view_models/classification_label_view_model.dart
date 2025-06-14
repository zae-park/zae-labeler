// 📁 sub_view_models/classification_label_view_model.dart

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

  bool get isMultiLabel => labelModel.isMultiClass;

  @override
  void updateLabel(dynamic labelData) async {
    ClassificationLabelModel newModel;

    if (isMultiLabel) {
      if (labelData is! Set<String>) {
        throw ArgumentError('Expected Set<String> for multi-label mode');
      }
      newModel = MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
    } else {
      if (labelData != null && labelData is! String) {
        throw ArgumentError('Expected String or null for single-label mode');
      }
      newModel = SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: labelData);
    }

    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  @override
  void toggleLabel(String labelItem) {
    final current = labelModel.label;

    if (isMultiLabel) {
      final currentSet = (current is Set<String>) ? Set<String>.from(current) : <String>{};
      if (currentSet.contains(labelItem)) {
        currentSet.remove(labelItem);
      } else {
        currentSet.add(labelItem);
      }
      updateLabel(currentSet);
    } else {
      updateLabel(current == labelItem ? null : labelItem);
    }
  }

  @override
  bool isLabelSelected(String labelItem) {
    final currentLabel = labelModel.label;
    if (isMultiLabel && currentLabel is Set<String>) {
      return currentLabel.contains(labelItem);
    } else {
      return currentLabel == labelItem;
    }
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
    if (labelData is! String) {
      throw ArgumentError('labelData must be a String in CrossClassification');
    }

    final previous = labelModel as CrossClassificationLabelModel;
    final newModel =
        CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: previous.label?.copyWith(relation: labelData));

    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    final prev = labelModel as CrossClassificationLabelModel;
    final current = prev.label;

    if (current == null) return;

    final toggled = current.relation == labelItem ? '' : labelItem;

    labelModel = CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: current.copyWith(relation: toggled));

    await saveLabel();
    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) {
    final model = labelModel as CrossClassificationLabelModel;
    return model.label?.relation == labelItem;
  }
}
