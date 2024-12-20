// lib/src/views/widgets/labeling_mode_dropdown.dart
import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class LabelingModeDropdown extends StatelessWidget {
  final LabelingMode selectedMode;
  final Function(LabelingMode) onModeChanged;

  const LabelingModeDropdown({
    Key? key,
    required this.selectedMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LabelingMode>(
      value: selectedMode,
      decoration: const InputDecoration(labelText: '라벨링 모드'),
      items: LabelingMode.values.map((mode) {
        final displayText = {
              LabelingMode.singleClassification: 'Single Classification',
              LabelingMode.multiClassification: 'Multi Classification',
              LabelingMode.segmentation: 'Segmentation',
            }[mode] ??
            mode.toString();
        return DropdownMenuItem<LabelingMode>(value: mode, child: Text(displayText));
      }).toList(),
      onChanged: (LabelingMode? newMode) => newMode != null && onModeChanged(newMode),
    );
  }
}
