// 📁 lib/src/views/pages/sub_pages/cross_classification_labeling_page.dart
import 'package:flutter/material.dart';

import '../../../../project/models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../../../../views/widgets/shared/viewer_builder.dart';
import 'base_labeling_page.dart';

class CrossClassificationLabelingPage extends BaseLabelingPage<CrossClassificationLabelingViewModel> {
  const CrossClassificationLabelingPage({Key? key, required Project project, required CrossClassificationLabelingViewModel viewModel})
      : super(key: key, project: project, viewModel: viewModel);

  @override
  Widget buildViewer(CrossClassificationLabelingViewModel vm) {
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
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: vm.isLabelSelected(label) ? Colors.blue : Colors.grey,
            ),
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
