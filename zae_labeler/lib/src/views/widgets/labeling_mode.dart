import 'package:flutter/material.dart';

/// ✅ 라벨링 모드 선택 위젯
class LabelModeSelector extends StatelessWidget {
  final String selectedMode; // 현재 선택된 모드
  final Function(String) onModeSelected; // 모드 선택 시 실행될 함수

  const LabelModeSelector({Key? key, required this.selectedMode, required this.onModeSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> modes = ['single_classification', 'multi_classification', 'segmentation'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: modes.map((mode) {
          String displayText = {
                'single_classification': 'Single Classification',
                'multi_classification': 'Multi Classification',
                'segmentation': 'Segmentation',
              }[mode] ??
              mode;

          bool isSelected = selectedMode == mode;

          return GestureDetector(
            onTap: () => onModeSelected(mode), // ✅ 콜백 실행
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
}
