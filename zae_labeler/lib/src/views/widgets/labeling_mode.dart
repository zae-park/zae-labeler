import 'package:flutter/material.dart';
import '../../models/project_model.dart';

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
        final displayText = _getModeDisplayText(mode);
        return DropdownMenuItem<LabelingMode>(value: mode, child: Text(displayText));
      }).toList(),
      onChanged: (LabelingMode? newMode) => newMode != null && onModeChanged(newMode),
    );
  }

  Widget _buildButtonSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: LabelingMode.values.map((mode) {
          String displayText = _getModeDisplayText(mode);
          bool isSelected = selectedMode == mode;

          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getModeDisplayText(LabelingMode mode) {
    return {
          LabelingMode.singleClassification: 'Single Classification',
          LabelingMode.multiClassification: 'Multi Classification',
          LabelingMode.segmentation: 'Segmentation',
        }[mode] ??
        mode.toString();
  }
}
