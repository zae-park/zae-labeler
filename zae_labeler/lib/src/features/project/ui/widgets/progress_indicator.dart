import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/label/use_cases/labeling_summary_use_case.dart';

class LabelingCircularProgressButton extends StatelessWidget {
  final LabelingSummary summary;
  final VoidCallback onPressed;

  const LabelingCircularProgressButton({super.key, required this.summary, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    if (total == 0) return const SizedBox();

    final completeRatio = summary.complete / total;
    final warningRatio = summary.warning / total;
    final completePlusWarningRatio = completeRatio + warningRatio;

    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: 1.0, strokeWidth: 8, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!)),
            CircularProgressIndicator(value: completePlusWarningRatio, strokeWidth: 8, valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange)),
            CircularProgressIndicator(value: completeRatio, strokeWidth: 8, valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, size: 28),
                const SizedBox(height: 4),
                Text('${summary.complete} / ${summary.total}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
