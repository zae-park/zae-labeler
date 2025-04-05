// 📁 views/widgets/shared/class_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../../../theme/theme.dart';

class ClassSelectorWidget extends StatelessWidget {
  final bool multiSelect;
  final void Function(String label) onLabelSelected;

  const ClassSelectorWidget({Key? key, required this.multiSelect, required this.onLabelSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final labelingVM = context.watch<LabelingViewModel>();
    final selectedLabels = labelingVM.currentLabelVM.labelModel.label;

    return Wrap(
      spacing: 8.0,
      children: labelingVM.project.classes.map((label) {
        final isSelected = multiSelect ? (selectedLabels is Set<String> && selectedLabels.contains(label)) : selectedLabels == label;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onLabelSelected(label),
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.black),
        );
      }).toList(),
    );
  }
}
