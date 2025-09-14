// 📁 lib/src/views/pages/sub_pages/cross_classification_labeling_page.dart
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';

import '../../../../../views/widgets/shared/viewer_builder.dart';
import 'base_labeling_page.dart';

class CrossClassificationLabelingPage extends BaseLabelingPage<CrossClassificationLabelingViewModel> {
  const CrossClassificationLabelingPage({super.key, required super.project, required super.viewModel, super.onSave});

  /// Viewer 교체: 소스/타겟을 좌우로 보여주는 2분할 구성
  @override
  Widget? buildViewerOverride(BuildContext context, CrossClassificationLabelingViewModel vm) {
    if (vm.totalCount == 0 || vm.currentPair == null) {
      return const Center(child: Text('쌍을 초기화하는 중입니다...'));
    }

    return Row(
      children: [
        Expanded(child: ViewerBuilder(data: vm.currentSourceData)),
        const VerticalDivider(width: 1),
        Expanded(child: ViewerBuilder(data: vm.currentTargetData)),
      ],
    );
  }

  @override
  Widget buildModeSpecificUI(CrossClassificationLabelingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: List.generate(project.classes.length, (index) {
          final label = project.classes[index];
          final isSelected = vm.isLabelSelected(label);
          return ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.blue : Colors.grey),
            onPressed: () => vm.updateLabel(label),
            child: Text(label),
          );
        }),
      ),
    );
  }

  @override
  void handleNumericKeyInput(CrossClassificationLabelingViewModel vm, int index) {
    if (index >= 0 && index < project.classes.length) {
      vm.updateLabel(project.classes[index]);
    }
  }
}
