import 'package:flutter/material.dart';
import '../../models/label_model.dart';
import '../../models/project_model.dart';
import 'not_found_page.dart';
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
  final modeToPageBuilder = {
    LabelingMode.singleClassification: (p) => ClassificationLabelingPage(project: p),
    LabelingMode.multiClassification: (p) => ClassificationLabelingPage(project: p),
    LabelingMode.crossClassification: (p) => CrossClassificationLabelingPage(project: p),
    LabelingMode.singleClassSegmentation: (p) => SegmentationLabelingPage(project: p),
    LabelingMode.multiClassSegmentation: (p) => SegmentationLabelingPage(project: p),
  };

  @override
  Widget build(BuildContext context) {
    return modeToPageBuilder[widget.project.mode]?.call(widget.project) ?? const NotFoundPage();
  }
}
