// lib/src/features/label/ui/pages/sub_pages/classification_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../view_models/classification_labeling_view_model.dart';
import '../../widgets/classification_label_selector.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<ClassificationLabelingViewModel> {
  const ClassificationLabelingPage({super.key, required super.viewModel});

  @override
  Widget buildModeSpecificUI(BuildContext context, ClassificationLabelingViewModel vm) {
    return ClassificationLabelSelector(classes: vm.project.classes, isSelected: vm.isLabelSelected, onToggle: vm.toggleLabel);
  }

  @override
  void handleNumericKeyInput(ClassificationLabelingViewModel vm, int index) {
    if (index >= 0 && index < vm.project.classes.length) {
      vm.applyShortcut(vm.project.classes[index]);
    }
  }
}
