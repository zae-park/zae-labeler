// lib/src/features/label/ui/widgets/classification_label_selector.dart
import 'package:flutter/material.dart';

import 'package:zae_labeler/src/views/widgets/core/buttons.dart';

/// 클래스 버튼 목록. 선택 여부와 토글 동작은 호출 측 VM이 제공합니다.
class ClassificationLabelSelector extends StatelessWidget {
  final List<String> classes;
  final bool Function(String label) isSelected;
  final Future<void> Function(String label) onToggle;

  const ClassificationLabelSelector({super.key, required this.classes, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: [for (final label in classes) LabelButton(isSelected: isSelected(label), onPressedFunc: () => onToggle(label), label: label)],
      ),
    );
  }
}
