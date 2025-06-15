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
    required super.labelInputMapper,
  });

  bool get isMultiLabel => labelModel.isMultiClass;

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
      updateLabelFromInput(currentSet);
    } else {
      updateLabelFromInput(current == labelItem ? null : labelItem);
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
    required super.labelInputMapper,
  });

  @override
  Future<void> toggleLabel(String labelItem) async {
    final prev = labelModel as CrossClassificationLabelModel;
    final current = prev.label;

    if (current == null) return;

    final toggled = current.relation == labelItem ? '' : labelItem;

    final toggledModel =
        CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: current.copyWith(relation: toggled));

    updateLabel(toggledModel);
  }

  @override
  bool isLabelSelected(String labelItem) {
    final model = labelModel as CrossClassificationLabelModel;
    return model.label?.relation == labelItem;
  }
}
