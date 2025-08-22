// 📁 lib/src/views/widgets/segmentation/segmentation_class_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart';

class SegmentationClassSelector extends StatelessWidget {
  final SegmentationLabelingViewModel? vm;
  const SegmentationClassSelector({super.key, this.vm});

  @override
  Widget build(BuildContext context) {
    final labelingVM = vm ?? context.watch<SegmentationLabelingViewModel>();
    final selected = labelingVM.selectedClass;

    return Wrap(
      spacing: 8.0,
      children: labelingVM.project.classes.map((label) {
        final isSelected = (selected == label);
        return ChoiceChip(label: Text(label), selected: isSelected, onSelected: (_) => labelingVM.setSelectedClass(label));
      }).toList(),
    );
  }
}
