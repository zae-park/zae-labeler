import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/data_model.dart';
import '../../../models/project_model.dart';
import '../../../utils/storage_helper.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeler.dart';
import 'base_labeling_page.dart';

class ClassificationLabelingPage extends BaseLabelingPage<LabelingViewModel> {
  @override
  final Project project;
  @override
  final List<UnifiedData>? fileDataList; // ✅ 추가

  const ClassificationLabelingPage({
    Key? key,
    required this.project,
    this.fileDataList, // ✅ 생성자에 추가
  }) : super(key: key, project: project, fileDataList: fileDataList);

  @override
  BaseLabelingPageState<LabelingViewModel> createState() => _ClassificationLabelingPageState();
}

class _ClassificationLabelingPageState extends BaseLabelingPageState<LabelingViewModel> {
  @override
  Widget buildModeSpecificUI(LabelingViewModel labelingVM) => LabelSelectorWidget(labelingVM: labelingVM);

  @override
  LabelingViewModel createViewModel() =>
      LabelingViewModelFactory.create(project, Provider.of<StorageHelperInterface>(context, listen: false), initialDataList: widget.fileDataList);

  @override
  void handleNumericKeyInput(LabelingViewModel labelingVM, int index) {
    if (index < labelingVM.project.classes.length) {
      labelingVM.updateLabel(labelingVM.project.classes[index]);
    }
  }
}
