import 'package:flutter/material.dart';

import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeler.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  const ClassificationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<LabelingViewModel> createState() => _ClassificationLabelingPageState();
}

class _ClassificationLabelingPageState extends BaseLabelingPageState<LabelingViewModel> {
  @override
  Widget buildModeSpecificUI(LabelingViewModel labelingVM) => LabelSelectorWidget(labelingVM: labelingVM);

  @override
  LabelingViewModel createViewModel() => LabelingViewModelFactory.create(project, StorageHelper.instance);

  @override
  void handleNumericKeyInput(LabelingViewModel labelingVM, int index) {
    if (index < labelingVM.project.classes.length) {
      labelingVM.updateLabel(labelingVM.project.classes[index]); // ✅ 즉시 적용
    }
  }
}
