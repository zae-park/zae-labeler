// lib/src/models/label_model.dart

import 'sub_models/base_label_model.dart';
export 'sub_models/base_label_model.dart';
import 'sub_models/classification_label_model.dart';
import 'sub_models/segmentation_label_model.dart';

enum LabelStatus { complete, warning, incomplete }

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
  singleClassification, // 단일 분류 (Single Classification) : 하나의 데이터에 대해 하나의 클래스를 지정
  multiClassification, // 다중 분류 (Multi Classification) : 하나의 데이터에 대해 여러 개의 클래스를 지정
  crossClassification, // 관계쌍 분류 (Cross Classification) : 두 데이터 쌍에 대해 하나의 클래스를 지정
  singleClassSegmentation, // 단일 클래스 세그멘테이션 (Single Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 단일 클래스를 지정
  multiClassSegmentation; // 다중 클래스 세그멘테이션 (Multi Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 다중 클래스를 지정

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

/// ✅ `LabelModel`에 대한 확장(Extension)을 사용하여 `createNew()` 팩토리 메서드 추가
extension LabelModelFactory on LabelModel {
  static LabelModel createNew(LabelingMode mode, {required String dataId}) {
    final now = DateTime.now();
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel(dataId: dataId, labeledAt: now, label: null);
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel(dataId: dataId, labeledAt: now, label: null);
      default:
        return SingleClassificationLabelModel(dataId: dataId, labeledAt: now, label: null);
    }
  }

  static Type expectedType(LabelingMode mode) {
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabelModel;
      case LabelingMode.multiClassification:
        return MultiClassificationLabelModel;
      case LabelingMode.crossClassification:
        return CrossClassificationLabelModel;
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabelModel;
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabelModel;
      default:
        throw UnimplementedError("Unsupported mode: $mode");
    }
  }
}
