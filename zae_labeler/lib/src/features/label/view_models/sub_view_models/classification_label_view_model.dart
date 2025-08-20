// 📁 sub_view_models/classification_label_view_model.dart

import 'base_label_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';

/// ViewModel for single and multi classification labeling
class ClassificationLabelViewModel extends LabelViewModel {
  ClassificationLabelViewModel({required super.project, required super.data, required super.labelUseCases, required super.initialLabel, required super.mapper});

  bool get isMultiLabel => labelModel.isMultiClass;

  @override
  Future<void> updateLabelFromInput(dynamic labelData) async {
    if (isMultiLabel) {
      // ✅ 내부 상태와 비교하여 Set<String> 업데이트
      final current = labelModel.label;
      final currentSet = (current is Set<String>) ? Set<String>.from(current) : <String>{};

      if (labelData is! String) {
        throw ArgumentError('Expected String for multi-label input');
      }

      if (currentSet.contains(labelData)) {
        currentSet.remove(labelData);
      } else {
        currentSet.add(labelData);
      }

      final newModel = MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: currentSet);

      await updateLabel(newModel);
    } else {
      // ✅ 단일 선택인 경우는 그대로 mapper에 위임
      await super.updateLabelFromInput(labelData);
    }
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    if (isMultiLabel) {
      // ✅ 다중 분류: 기존 로직 그대로 사용 (선택/해제 토글)
      await updateLabelFromInput(labelItem);
    } else {
      // ✅ 단일 분류: 같은 라벨을 다시 누르면 선택 해제 (null로 설정)
      final currentLabel = labelModel.label;
      final newLabel = (currentLabel == labelItem) ? null : labelItem;
      await super.updateLabelFromInput(newLabel);
      // 🔍 설명: super.updateLabelFromInput을 호출하면
      // LabelInputMapper를 통해 SingleClassificationLabelModel을 생성하고,
      // LabelViewModel.updateLabel() → saveLabel()을 거쳐 상태를 저장합니다.
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
  CrossClassificationLabelViewModel(
      {required super.project, required super.data, required super.labelUseCases, required super.initialLabel, required super.mapper});

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
