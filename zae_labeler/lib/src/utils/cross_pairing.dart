// lib/src/utils/cross_pairing.dart

import '../core/models/label/classification_label_model.dart';

/// ✅ 선택한 데이터 ID 목록으로 CrossDataPair 쌍을 생성
List<CrossDataPair> generateCrossPairs(List<String> dataIds) {
  final List<CrossDataPair> pairs = [];

  for (int i = 0; i < dataIds.length; i++) {
    for (int j = i + 1; j < dataIds.length; j++) {
      pairs.add(CrossDataPair(
        sourceId: dataIds[i],
        targetId: dataIds[j],
        relation: '', // 초기에는 관계 미지정
      ));
    }
  }

  return pairs;
}
