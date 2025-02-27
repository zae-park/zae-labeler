// lib/src/models/label_entry.dart

import 'label_models/classification_label_model.dart';
import 'label_models/segmentation_label_model.dart';

/*
이 파일은 라벨링 모드를 정의하는 열거형과 데이터 파일에 대한 라벨 정보의 정의를 포함합니다.
  - LabelingMode는 프로젝트 설정 및 라벨링 작업에서 사용됩니다.
  - LabelEntry 클래스는 단일 분류(Single Classification), 다중 분류(Multi Classification), 세그멘테이션(Segmentation) 등의 작업을 지원하며,
    현재 프로젝트의 LabelingMode에 따라 단일 라벨 정보만 저장합니다.
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
  /// ✅ 단일 분류 (Single Classification)
  /// - 하나의 데이터 포인트에 대해 하나의 클래스를 지정.
  singleClassification,

  /// ✅ 다중 분류 (Multi Classification)
  /// - 하나의 데이터 포인트에 대해 여러 개의 클래스를 지정 가능.
  multiClassification,

  /// ✅ 단일 클래스 세그멘테이션 (Single Class Segmentation)
  /// - 이미지 또는 시계열 데이터에서 특정 영역을 분할하여 라벨링.
  /// - 단일 클래스에 대한 세그멘테이션 정보만 저장.
  singleClassSegmentation,

  /// ✅ 다중 클래스 세그멘테이션 (Multi Class Segmentation)
  /// - 이미지 또는 시계열 데이터에서 특정 영역을 분할하여 라벨링.
  /// - 하나의 pixel, grid 등에 다중 클래스에 대한 세그멘테이션 정보만 저장.
  multiClassSegmentation,
}

/// ✅ 특정 데이터 파일에 대한 라벨 정보를 저장하는 클래스.
/// - 프로젝트의 `LabelingMode`에 따라 하나의 라벨만 포함.
/// - 단일 분류, 다중 분류 또는 세그멘테이션 중 하나만 저장됨.
///
/// 📌 **예제 코드**
/// ```dart
/// LabelEntry entry = LabelEntry(
///   dataFilename: "image1.png",
///   dataPath: "/dataset/images/image1.png",
///   labelingMode: LabelingMode.singleClassification,
///   label: SingleClassificationLabel(labeledAt: "2024-06-10T12:00:00Z", label: "cat"),
/// );
///
/// print(entry.toJson());
/// ```
class LabelEntry<T> {
  final String dataFilename; // **데이터 파일 이름**
  final String dataPath; // **데이터 파일 경로**
  final LabelingMode labelingMode; // **해당 Entry가 속한 Labeling Mode**

  /// **라벨 데이터 (T 타입)**
  /// - `LabelingMode`에 따라 `T`는 `SingleClassificationLabel`, `MultiClassificationLabel`, `SegmentationLabel` 중 하나.
  final T? labelData;

  LabelEntry({required this.dataFilename, required this.dataPath, required this.labelingMode, required this.labelData});

  /// **빈 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.empty(LabelingMode mode) {
    return LabelEntry(dataFilename: '', dataPath: '', labelingMode: mode, labelData: null);
  }

  /// **LabelEntry 객체를 JSON 형식으로 변환.**
  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'labeling_mode': labelingMode.toString().split('.').last,
        'label_data': labelData is SingleClassificationLabel
            ? (labelData as SingleClassificationLabel).toJson()
            : labelData is MultiClassificationLabel
                ? (labelData as MultiClassificationLabel).toJson()
                : labelData is SegmentationLabel
                    ? (labelData as SegmentationLabel).toJson()
                    : null,
      };

  /// **JSON 데이터를 기반으로 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.fromJson(Map<String, dynamic> json) {
    LabelingMode mode =
        LabelingMode.values.firstWhere((e) => e.toString().split('.').last == json['labeling_mode'], orElse: () => LabelingMode.singleClassification);

    dynamic labelData;
    if (mode == LabelingMode.singleClassification) {
      labelData = json['label_data'] != null ? SingleClassificationLabel.fromJson(json['label_data']) : null;
    } else if (mode == LabelingMode.multiClassification) {
      labelData = json['label_data'] != null ? MultiClassificationLabel.fromJson(json['label_data']) : null;
    } else if (mode == LabelingMode.singleClassSegmentation) {
      labelData = json['label_data'] != null ? SingleClassSegmentationLabel.fromJson(json['label_data']) : null;
    } else if (mode == LabelingMode.multiClassSegmentation) {
      labelData = json['label_data'] != null ? MultiClassSegmentationLabel.fromJson(json['label_data']) : null;
    }

    return LabelEntry(
        dataFilename: json['data_filename'] ?? 'unknown.json', dataPath: json['data_path'] ?? 'unknown_path', labelingMode: mode, labelData: labelData);
  }
}
