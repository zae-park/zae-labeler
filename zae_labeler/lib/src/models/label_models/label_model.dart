// lib/src/models/label_model.dart

/*
이 파일은 라벨링 모드를 정의하는 열거형과 하위 라벨 클래스를 위한 추상 클래스를 포함합니다.
  - LabelingMode는 프로젝트 설정 및 라벨링 작업에서 사용됩니다.
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
  singleClassification, // 단일 분류 (Single Classification) : 하나의 데이터에 대해 하나의 클래스를 지정
  multiClassification, // 다중 분류 (Multi Classification) : 하나의 데이터에 대해 여러 개의 클래스를 지정
  singleClassSegmentation, // 단일 클래스 세그멘테이션 (Single Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 단일 클래스를 지정
  multiClassSegmentation; // 다중 클래스 세그멘테이션 (Multi Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 다중 클래스를 지정

  String get displayName {
    switch (this) {
      case LabelingMode.singleClassification:
        return 'Single Classification';
      case LabelingMode.multiClassification:
        return 'Multi Classification';
      case LabelingMode.singleClassSegmentation:
        return 'Segmentation (Binary)';
      case LabelingMode.multiClassSegmentation:
        return 'Segmentation (Multi-Class)';
    }
  }
}

/// ✅ LabelType의 최상위 클래스 (모든 Label의 기본 인터페이스)
abstract class LabelModel {
  String labeledAt; // 라벨이 부여된 시간 (ISO 8601 형식)

  LabelModel({required this.labeledAt});

  /// JSON 변환 메서드 (모든 Label 모델이 구현해야 함)
  Map<String, dynamic> toJson();
}
