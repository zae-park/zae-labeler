// 📁 lib/src/views/pages/sub_pages/classification_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/views/widgets/classification/classification_label_selector.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<ClassificationLabelingViewModel> {
  const ClassificationLabelingPage({super.key, required super.project, required super.viewModel, super.onSave});

  @override
  Widget buildModeSpecificUI(ClassificationLabelingViewModel vm) {
    return ClassificationLabelSelector(vm: vm);
  }

  @override
  void handleNumericKeyInput(ClassificationLabelingViewModel vm, int index) {
    if (index >= 0 && index < vm.project.classes.length) {
      vm.updateLabel(vm.project.classes[index]);
    }
  }
}
