// 📁 sub_view_models/classification_label_view_model.dart

import 'package:zae_labeler/src/features/label/logic/label_input_mapper.dart';
import '../../../../core/models/project/project_model.dart';
import '../../../../core/models/data/unified_data.dart';

import '../../models/label_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import 'base_label_view_model.dart';

/// 단일/다중 분류 공용 ViewModel
class ClassificationLabelViewModel extends LabelViewModel {
  ClassificationLabelViewModel(
      {required Project project, required UnifiedData data, required super.labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper})
      : super(project: project, data: data, initialLabel: initialLabel, mapper: mapper ?? LabelInputMapper.forMode(project.mode));

  /// 다중 분류 여부
  bool get isMultiLabel => (project.mode == LabelingMode.multiClassification) || (labelModel is MultiClassificationLabelModel);

  @override
  Future<void> updateLabelFromInput(dynamic labelData) async {
    if (isMultiLabel) {
      // 다중 분류: 토글 방식으로 Set<String> 갱신
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
      // 단일 분류: 매퍼에게 위임 (null 허용 → 해제)
      await super.updateLabelFromInput(labelData);
    }
  }

  @override
  Future<void> toggleLabel(String labelItem) async {
    if (isMultiLabel) {
      await updateLabelFromInput(labelItem);
    } else {
      final currentLabel = labelModel.label;
      final newLabel = (currentLabel == labelItem) ? null : labelItem;
      await super.updateLabelFromInput(newLabel);
    }
  }

  @override
  bool isLabelSelected(String labelItem) {
    final v = labelModel.label;
    if (isMultiLabel && v is Set<String>) return v.contains(labelItem);
    return v == labelItem;
  }
}

/// nC2 관계쌍 분류용 ViewModel
class CrossClassificationLabelViewModel extends LabelViewModel {
  CrossClassificationLabelViewModel(
      {required Project project, required UnifiedData data, required super.labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper})
      : super(project: project, data: data, initialLabel: initialLabel, mapper: mapper ?? LabelInputMapper.forMode(project.mode));

  @override
  Future<void> toggleLabel(String labelItem) async {
    final prev = labelModel as CrossClassificationLabelModel;
    final current = prev.label;
    if (current == null) return;

    final toggled = current.relation == labelItem ? '' : labelItem;

    // NOTE: CrossDataPair에 copyWith가 있다고 가정
    final next = CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: current.copyWith(relation: toggled));
    await updateLabel(next);
  }

  @override
  bool isLabelSelected(String labelItem) {
    final model = labelModel as CrossClassificationLabelModel;
    return model.label?.relation == labelItem;
  }
}
