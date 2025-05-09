import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/project_model.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeler.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  final Project project;

  const ClassificationLabelingPage({Key? key, required this.project}) : super(key: key, project: project);

  @override
  BaseLabelingPageState<LabelingViewModel> createState() => _ClassificationLabelingPageState();
}

class _ClassificationLabelingPageState extends BaseLabelingPageState<LabelingViewModel> {
  @override
  Widget buildModeSpecificUI(LabelingViewModel labelingVM) => LabelSelectorWidget(labelingVM: labelingVM);

  @override
  LabelingViewModel createViewModel() =>
      LabelingViewModelFactory.create(project, Provider.of<StorageHelperInterface>(context, listen: false));

  @override
  void handleNumericKeyInput(LabelingViewModel labelingVM, int index) {
    if (index < labelingVM.project.classes.length) {
      labelingVM.updateLabel(labelingVM.project.classes[index]); // ✅ 즉시 적용
    }
  }
}