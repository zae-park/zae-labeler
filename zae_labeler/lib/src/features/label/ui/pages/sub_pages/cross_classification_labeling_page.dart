// lib/src/features/label/ui/pages/sub_pages/cross_classification_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../view_models/classification_labeling_view_model.dart';
import '../../widgets/classification_label_selector.dart';
import '../../widgets/viewers/viewer_builder.dart';
import 'base_labeling_page.dart';

class CrossClassificationLabelingPage extends BaseLabelingPage<CrossClassificationLabelingViewModel> {
  const CrossClassificationLabelingPage({super.key, required super.viewModel});

  @override
  Widget buildViewer(BuildContext context, CrossClassificationLabelingViewModel vm) {
    if (vm.currentPair == null) {
      return const Center(child: Text('교차 분류에는 데이터가 2개 이상 필요합니다.'));
    }
    if (vm.isRenderPending) return const Center(child: CircularProgressIndicator());
    return Row(
      children: [
        Expanded(child: ViewerBuilder(data: vm.currentSourceData)),
        const VerticalDivider(width: 1),
        Expanded(child: ViewerBuilder(data: vm.currentTargetData)),
      ],
    );
  }

  @override
  Widget buildModeSpecificUI(BuildContext context, CrossClassificationLabelingViewModel vm) {
    return ClassificationLabelSelector(classes: vm.project.classes, isSelected: vm.isLabelSelected, onToggle: vm.toggleLabel);
  }

  @override
  void handleNumericKeyInput(CrossClassificationLabelingViewModel vm, int index) {
    if (index >= 0 && index < vm.project.classes.length) {
      vm.setRelation(vm.project.classes[index]);
    }
  }
}
