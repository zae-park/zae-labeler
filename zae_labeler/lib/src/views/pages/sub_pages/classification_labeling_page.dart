import 'package:flutter/material.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import 'base_labeling_page.dart';
import '../../widgets/labeler.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  const ClassificationLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<LabelingViewModel> createState() => _ClassificationLabelingPageState();
}

class _ClassificationLabelingPageState extends BaseLabelingPageState<LabelingViewModel> {
  @override
  Widget buildModeSpecificUI(LabelingViewModel labelingVM) {
    return LabelSelectorWidget(labelingVM: labelingVM); // ✅ Label 선택 UI
  }

  @override
  LabelingViewModel createViewModel() {
    return LabelingViewModel(project: project, storageHelper: StorageHelper.instance);
  }
}
