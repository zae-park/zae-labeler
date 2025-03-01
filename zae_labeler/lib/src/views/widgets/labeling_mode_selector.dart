import 'package:flutter/material.dart';
import '../../models/label_entry.dart';

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
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
                border: isSelected ? Border.all(color: Colors.blue, width: 2.0) : null,
                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 3))] : [],
              ),
              child: Text(
                mode.displayName, // ✅ Enum의 displayName 사용
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
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
}
