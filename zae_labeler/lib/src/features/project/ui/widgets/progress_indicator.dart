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
        width: 110, // 🔹 확대
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 회색: 전체 배경
            CircularProgressIndicator(value: 1.0, strokeWidth: 6, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!)),
            // 노랑: warning 포함 영역
            CircularProgressIndicator(
              value: warningRatio + completeRatio,
              strokeWidth: 6,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            // 파랑: 정상 완료 영역
            CircularProgressIndicator(
              value: completeRatio,
              strokeWidth: 6,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            // 중앙 컨텐츠
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 28),
                const SizedBox(height: 4),
                Text('${summary.complete} / ${summary.total}', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
