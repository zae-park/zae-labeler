// 📁 lib/src/views/pages/sub_pages/classification_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';
import '../../../../../core/models/project/project_model.dart';
import 'package:zae_labeler/src/views/widgets/classification/classification_label_selector.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<ClassificationLabelingViewModel> {
  const ClassificationLabelingPage({Key? key, required Project project, required ClassificationLabelingViewModel viewModel})
      : super(key: key, project: project, viewModel: viewModel);

  @override
  Widget buildModeSpecificUI(ClassificationLabelingViewModel vm) {
    return ClassificationLabelSelector(vm: vm);
  }

  @override
  void handleNumericKeyInput(ClassificationLabelingViewModel vm, int index) {
    if (index >= 0 && index < vm.project.classes.length) {
      // 숫자 단축키: 단일분류는 선택, 다중분류는 토글을 내부 VM이 알아서 처리
      vm.updateLabel(vm.project.classes[index]);
      // 혹은 명시적으로 토글 동작을 쓰고 싶다면:
      // vm.toggleLabel(vm.project.classes[index]);
    }
  }
}
