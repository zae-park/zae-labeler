import 'base_labeling_view_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';

class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({
    required super.project,
    required super.storageHelper,
  });

  @override
  Future<void> updateLabel(dynamic labelData) async {
    final labelVM = currentLabelVM;

    // Classification인 경우
    if (labelVM.labelModel is ClassificationLabelModel) {
      final model = labelVM.labelModel as ClassificationLabelModel;

      labelVM.labelModel = model.isMultiClass
          ? model.toggleLabel(labelData) // ✅ 다중 선택: toggle
          : model.updateLabel(labelData); // ✅ 단일 선택: 덮어쓰기

      print("[updateLabel] selected: ${labelVM.labelModel.label}");
      await labelVM.saveLabel();
      notifyListeners();
    } else if (labelVM.labelModel is SegmentationLabelModel) {
      throw UnimplementedError('SegmentationLabelModel은 ClassificationLabelingViewModel에서 지원하지 않습니다.');
    }

    // (Segmentation 등의 타입은 개별 구현에서 override)
  }

  @override
  void toggleLabel(String labelItem) {
    final labelVM = currentLabelVM;

    if (labelVM.labelModel is ClassificationLabelModel) {
      final model = labelVM.labelModel as ClassificationLabelModel;
      labelVM.labelModel = model.toggleLabel(labelItem);
      notifyListeners();
    }
  }

  @override
  bool isLabelSelected(String labelItem) => currentLabelVM.labelModel.isSelected(labelItem);
}
