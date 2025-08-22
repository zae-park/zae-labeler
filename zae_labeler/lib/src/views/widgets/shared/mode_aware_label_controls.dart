// 📁 views/widgets/shared/mode_aware_label_controls.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:zae_labeler/src/features/label/view_models/sub_view_models/base_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart';

import '../classification/classification_label_selector.dart';
import '../segmentation/segmentation_class_selector.dart';
import '../segmentation/grid_painter.dart';

class ModeAwareLabelControls extends StatelessWidget {
  const ModeAwareLabelControls({super.key});

  @override
  Widget build(BuildContext context) {
    final baseVm = context.watch<LabelingViewModel>();

    if (baseVm is ClassificationLabelingViewModel) {
      return ClassificationLabelSelector(vm: baseVm);
    }

    if (baseVm is SegmentationLabelingViewModel) {
      return const Column(children: [SegmentationClassSelector(), SizedBox(height: 8), GridPainterWidget(mode: SegmentationMode.pixelMask)]);
    }

    return const SizedBox.shrink();
  }
}
