// lib/src/models/label_model.dart

import 'sub_models/base_label_model.dart';
import 'sub_models/classification_label_model.dart';
import 'sub_models/segmentation_label_model.dart';

/*
이 파일은 라벨링 모드 열거형을 정의하고, 각 모드에 맞는 LabelModel을 생성하는 기능을 포함합니다.
*/

/// ✅ 라벨링 모드 열거형 (Labeling Mode Enum)
enum LabelModelFactory {
  singleClassification, // 단일 분류
  multiClassification, // 다중 분류
  singleClassSegmentation, // 단일 클래스 세그멘테이션
  multiClassSegmentation; // 다중 클래스 세그멘테이션

  /// ✅ 해당 모드의 표시 이름 반환
  String get displayName {
    switch (this) {
      case LabelModelFactory.singleClassification:
        return 'Single Classification';
      case LabelModelFactory.multiClassification:
        return 'Multi Classification';
      case LabelModelFactory.singleClassSegmentation:
        return 'Segmentation (Binary)';
      case LabelModelFactory.multiClassSegmentation:
        return 'Segmentation (Multi-Class)';
    }
  }

  /// ✅ 해당 모드에 맞는 LabelModel 생성 (팩토리 역할 수행)
  LabelModel createLabel() {
    switch (this) {
      case LabelModelFactory.singleClassification:
        return SingleClassificationLabelModel.empty();
      case LabelModelFactory.multiClassification:
        return MultiClassificationLabelModel.empty();
      case LabelModelFactory.singleClassSegmentation:
        return SingleClassSegmentationLabelModel.empty();
      case LabelModelFactory.multiClassSegmentation:
        return MultiClassSegmentationLabelModel.empty();
    }
  }
}
