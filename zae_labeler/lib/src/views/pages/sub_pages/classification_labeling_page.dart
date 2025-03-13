import 'package:flutter/material.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/core/buttons.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  const ClassificationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<LabelingViewModel> createState() => _ClassificationLabelingPageState();
}

class _ClassificationLabelingPageState extends BaseLabelingPageState<LabelingViewModel> {
  @override
  Widget buildBody(LabelingViewModel labelingVM) {
    return Column(
      children: [
        Expanded(child: _buildViewer(labelingVM)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            children: List.generate(labelingVM.project.classes.length, (index) {
              final label = labelingVM.project.classes[index];
              return LabelButton(
                isSelected: labelingVM.isLabelSelected(label),
                onPressedFunc: () async => await labelingVM.addOrUpdateLabel(label),
                label: label,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildViewer(LabelingViewModel labelingVM) {
    return Container(); // 실제 뷰어 로직 추가
  }

  @override
  LabelingViewModel createViewModel() {
    return LabelingViewModel(project: project, storageHelper: StorageHelper.instance);
  }
}
