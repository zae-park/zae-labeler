// 📁 views/pages/sub_pages/cross_classification_labeling_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_models/labeling_view_model.dart';
import '../../../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../../widgets/shared/viewer_builder.dart';
import 'base_labeling_page.dart';

class CrossClassificationLabelingPage extends BaseLabelingPage<CrossClassificationLabelingViewModel> {
  const CrossClassificationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<CrossClassificationLabelingViewModel> createState() => _CrossClassificationLabelingPageState();
}

class _CrossClassificationLabelingPageState extends BaseLabelingPageState<CrossClassificationLabelingViewModel> {
  @override
  CrossClassificationLabelingViewModel createViewModel() {
    return LabelingViewModelFactory.create(
      project,
      Provider.of<StorageHelperInterface>(context, listen: false),
    ) as CrossClassificationLabelingViewModel;
  }

  @override
  Widget buildViewer(CrossClassificationLabelingViewModel labelingVM) {
    if (labelingVM.totalPairCount == 0 || labelingVM.currentPair == null) {
      return const Center(child: Text('쌍을 초기화하는 중입니다...'));
    }

    return Row(
      children: [
        Expanded(child: ViewerBuilder(data: labelingVM.currentSourceData)),
        const VerticalDivider(width: 1),
        Expanded(child: ViewerBuilder(data: labelingVM.currentTargetData)),
      ],
    );
  }

  @override
  Widget buildModeSpecificUI(CrossClassificationLabelingViewModel labelingVM) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: List.generate(project.classes.length, (index) {
          final label = project.classes[index];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: labelingVM.isLabelSelected(label) ? Colors.blue : Colors.grey,
            ),
            onPressed: () => labelingVM.updateLabel(label),
            child: Text(label),
          );
        }),
      ),
    );
  }

  @override
  void handleNumericKeyInput(CrossClassificationLabelingViewModel labelingVM, int index) {
    if (index >= 0 && index < project.classes.length) {
      labelingVM.updateLabel(project.classes[index]);
    }
  }
}
