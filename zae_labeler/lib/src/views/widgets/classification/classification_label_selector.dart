// 📁 lib/src/views/widgets/classification/classification_label_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/views/widgets/core/buttons.dart';

class ClassificationLabelSelector extends StatelessWidget {
  final ClassificationLabelingViewModel? vm; // 직접 주입도 가능
  const ClassificationLabelSelector({super.key, this.vm});

  @override
  Widget build(BuildContext context) {
    final labelingVM = vm ?? context.watch<ClassificationLabelingViewModel>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: labelingVM.project.classes.map((label) {
          final selected = labelingVM.isLabelSelected(label);
          return LabelButton(isSelected: selected, onPressedFunc: () async => await labelingVM.toggleLabel(label), label: label);
        }).toList(),
      ),
    );
  }
}
