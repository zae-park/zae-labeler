// lib/src/features/label/ui/widgets/labeling_progress.dart
import 'package:flutter/material.dart';

import '../../view_models/labeling_view_model.dart';

/// "데이터 i / n - 이름" 위치 표시.
class LabelingProgress extends StatelessWidget {
  final LabelingViewModel labelingVM;

  const LabelingProgress({super.key, required this.labelingVM});

  @override
  Widget build(BuildContext context) {
    final vm = labelingVM;
    final position = vm.totalCount == 0 ? '0 / 0' : '${vm.currentIndex + 1} / ${vm.totalCount}';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('데이터 $position - ${vm.currentItemName}', style: const TextStyle(fontSize: 16)),
    );
  }
}
