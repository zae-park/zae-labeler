import '../../models/sub_models/classification_label_model.dart';
import 'base_labeling_view_model.dart';

class ClassificationLabelingViewModel extends LabelingViewModel {
  ClassificationLabelingViewModel({
    required super.project,
    required super.storageHelper,
  });

  @override
  Future<void> toggleLabel(String labelItem) async {
    final labelVM = currentLabelVM;
    if (labelVM.labelModel is ClassificationLabelModel) {
      labelVM.labelModel = (labelVM.labelModel as ClassificationLabelModel).toggleLabel(labelItem);
      await labelVM.saveLabel();
      notifyListeners();
    }
  }

  @override
  Future<void> updateLabel(dynamic labelData) async {
    currentLabelVM.updateLabel(labelData);
    await currentLabelVM.saveLabel();
    notifyListeners();
  }

  @override
  bool isLabelSelected(String labelItem) {
    return currentLabelVM.labelModel.isSelected(labelItem);
  }
}
