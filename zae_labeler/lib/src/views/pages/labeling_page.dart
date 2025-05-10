import 'package:flutter/material.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import 'sub_pages/classification_labeling_page.dart';
import 'sub_pages/segmentation_labeling_page.dart';
import 'sub_pages/cross_classification_labeling_page.dart';

class LabelingPage extends StatefulWidget {
  final Project project;

  const LabelingPage({Key? key, required this.project}) : super(key: key);

  @override
  LabelingPageState createState() => LabelingPageState();
}

class LabelingPageState extends State<LabelingPage> {
  @override
  Widget build(BuildContext context) {
    final mode = widget.project.mode;

    if (mode == LabelingMode.singleClassSegmentation || mode == LabelingMode.multiClassSegmentation) {
      return SegmentationLabelingPage(project: widget.project);
    } else if (mode == LabelingMode.crossClassification) {
      return CrossClassificationLabelingPage(project: widget.project);
    } else {
      return ClassificationLabelingPage(project: widget.project);
    }
  }
}
