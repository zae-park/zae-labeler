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

    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 회색 베이스
            SizedBox.expand(
              child: CircularProgressIndicator(value: 1.0, strokeWidth: 8, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!)),
            ),

            // 노란 경고 표시 (complete + warning)
            SizedBox.expand(
              child: CircularProgressIndicator(
                  value: completeRatio + warningRatio, strokeWidth: 8, valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange)),
            ),

            // 파란 정상 표시 (complete)
            SizedBox.expand(
              child: CircularProgressIndicator(value: completeRatio, strokeWidth: 8, valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
            ),

            // 중앙 텍스트 및 아이콘
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
