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

  const LabelingPage({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LabelingViewModel>(
      future: LabelingViewModelFactory.createAsync(project, Provider.of(context, listen: false)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final vm = snapshot.data!;
        final mode = project.mode;

        switch (mode) {
          case LabelingMode.singleClassification:
          case LabelingMode.multiClassification:
            return ClassificationLabelingPage(project: project, viewModel: vm as ClassificationLabelingViewModel);

          case LabelingMode.crossClassification:
            return CrossClassificationLabelingPage(project: project, viewModel: vm as CrossClassificationLabelingViewModel);

          case LabelingMode.singleClassSegmentation:
          case LabelingMode.multiClassSegmentation:
            return SegmentationLabelingPage(project: project, viewModel: vm as SegmentationLabelingViewModel);
          default:
            return const NotFoundPage();
        }
      },
    );
  }
}
