// core/models/label/label_types.dart

/*
이 파일은 라벨링 모드를 정의하는 열거형과 매핑을 포함합니다..
*/

/// ✅ 라벨링 모드 열거형 (Labeling Mode Enum)
/// - 프로젝트와 라벨링 작업에서 사용되는 주요 모드를 정의함.
///
/// 📌 **LabelingMode 종류**
/// ```dart
/// LabelingMode.singleClassification  // 단일 분류
/// LabelingMode.multiClassification   // 다중 분류
/// LabelingMode.segmentation          // 세그멘테이션
/// ```
///
/// 📌 **예제 코드**
/// ```dart
/// LabelingMode mode = LabelingMode.singleClassification;
/// print(mode.toString());  // "LabelingMode.singleClassification"
/// ```
enum LabelingMode {
  singleClassification,
  multiClassification,
  crossClassification,
  singleClassSegmentation,
  multiClassSegmentation;

  String get displayName {
    switch (this) {
      case LabelingMode.singleClassification:
        return 'Single Classification';
      case LabelingMode.multiClassification:
        return 'Multi Classification';
      case LabelingMode.crossClassification:
        return 'Cross Classification';
      case LabelingMode.singleClassSegmentation:
        return 'Segmentation (Binary)';
      case LabelingMode.multiClassSegmentation:
        return 'Segmentation (Multi-Class)';
    }
  }
}

/// 라벨 상태가 공용
enum LabelStatus { complete, warning, incomplete }
