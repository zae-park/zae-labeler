import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import '../../view_models/labeling_view_model.dart';
import 'not_found_page.dart';
import 'sub_pages/classification_labeling_page.dart';
import 'sub_pages/segmentation_labeling_page.dart';
import 'sub_pages/cross_classification_labeling_page.dart';

class LabelingPage extends StatelessWidget {
  final Project project;
  final LabelingViewModel viewModel;

  const LabelingPage({Key? key, required this.project, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modeToPageBuilder = {
      LabelingMode.singleClassification: (Project p, LabelingViewModel vm) => ClassificationLabelingPage(project: p, viewModel: vm),
      LabelingMode.multiClassification: (Project p, LabelingViewModel vm) => ClassificationLabelingPage(project: p, viewModel: vm),
      LabelingMode.crossClassification: (Project p, LabelingViewModel vm) => CrossClassificationLabelingPage(project: p, viewModel: vm),
      LabelingMode.singleClassSegmentation: (Project p, LabelingViewModel vm) => SegmentationLabelingPage(project: p, viewModel: vm),
      LabelingMode.multiClassSegmentation: (Project p, LabelingViewModel vm) => SegmentationLabelingPage(project: p, viewModel: vm),
    };

    final builder = modeToPageBuilder[project.mode];
    if (builder == null) return const NotFoundPage();

    return ChangeNotifierProvider<LabelingViewModel>.value(value: viewModel, child: builder(project, viewModel));
  }
}
