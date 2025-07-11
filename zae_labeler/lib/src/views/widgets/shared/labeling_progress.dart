// 📁 views/widgets/shared/labeling_progress.dart
import 'package:flutter/material.dart';
import '../../../features/label/view_models/labeling_view_model.dart';

class LabelingProgress extends StatelessWidget {
  final LabelingViewModel labelingVM;

  const LabelingProgress({super.key, required this.labelingVM});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '데이터 ${labelingVM.currentIndex + 1} / ${labelingVM.totalCount} - ${labelingVM.currentDataFileName}',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
