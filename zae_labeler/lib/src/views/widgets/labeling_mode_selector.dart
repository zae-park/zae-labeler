import 'package:flutter/material.dart';
import '../../features/label/models/label_model.dart';
import '../../../theme/theme.dart';

class LabelingModeSelector extends StatelessWidget {
  final LabelingMode selectedMode;
  final Function(LabelingMode) onModeChanged;
  final bool useDropdown;

  const LabelingModeSelector.dropdown({Key? key, required this.selectedMode, required this.onModeChanged})
      : useDropdown = true,
        super(key: key);

  const LabelingModeSelector.button({Key? key, required this.selectedMode, required this.onModeChanged})
      : useDropdown = false,
        super(key: key);

  @override
  Widget build(BuildContext context) => useDropdown ? _buildDropdown() : _buildButtonSelector();

  Widget _buildDropdown() {
    return DropdownButtonFormField<LabelingMode>(
      value: selectedMode,
      decoration: const InputDecoration(labelText: '라벨링 모드'),
      items: LabelingMode.values.map((mode) {
        return DropdownMenuItem<LabelingMode>(value: mode, child: Text(mode.displayName));
      }).toList(),
      onChanged: (LabelingMode? newMode) => newMode != null ? onModeChanged(newMode) : null,
    );
  }

  Widget _buildButtonSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: LabelingMode.values.map((mode) {
          bool isSelected = selectedMode == mode;

          return InkWell(
            onTap: () => onModeChanged(mode),
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: AppTheme.buttonDecoration(isSelected: isSelected),
              child: Text(mode.displayName, style: AppTheme.buttonTextStyle(isSelected: isSelected)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
