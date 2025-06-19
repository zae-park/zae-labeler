// 📁 lib/src/views/pages/sub_pages/classification_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeler.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  const ClassificationLabelingPage({Key? key, required Project project, required LabelingViewModel viewModel})
      : super(key: key, project: project, viewModel: viewModel);

  @override
  Widget buildModeSpecificUI(LabelingViewModel vm) => LabelSelectorWidget(labelingVM: vm);

  @override
  void handleNumericKeyInput(LabelingViewModel vm, int index) {
    if (index < vm.project.classes.length) {
      vm.updateLabel(vm.project.classes[index]);
    }
  }
}
