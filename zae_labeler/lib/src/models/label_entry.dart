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

  /// ✅ 세그멘테이션 (Segmentation)
  /// - 이미지 또는 시계열 데이터에서 특정 영역을 분할하여 라벨링.
  segmentation,
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
class LabelEntry {
  /// **데이터 파일 이름**
  /// - 라벨이 적용된 데이터 파일의 이름.
  final String dataFilename;

  /// **데이터 파일 경로**
  /// - 해당 데이터 파일이 저장된 경로.
  final String dataPath;

  /// **해당 Entry가 속한 Labeling Mode**
  /// - 프로젝트 생성 시 설정된 LabelingMode를 기반으로 동작.
  final LabelingMode labelingMode;

  /// **단일 라벨 데이터 (LabelingMode에 따라 타입이 달라짐)**
  /// - `labelingMode`가 `singleClassification`이면 `SingleClassificationLabel` 저장.
  /// - `labelingMode`가 `multiClassification`이면 `MultiClassificationLabel` 저장.
  /// - `labelingMode`가 `segmentation`이면 `SegmentationLabel` 저장.
  final dynamic label;

  LabelEntry({
    required this.dataFilename,
    required this.dataPath,
    required this.labelingMode,
    required this.label,
  });

  /// **빈 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.empty() => LabelEntry(
        dataFilename: '',
        dataPath: '',
        labelingMode: LabelingMode.singleClassification,
        label: null,
      );

  /// **LabelEntry 객체를 JSON 형식으로 변환.**
  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'labeling_mode': labelingMode.toString().split('.').last,
        'label': label?.toJson(),
      };

  /// **JSON 데이터를 기반으로 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.fromJson(Map<String, dynamic> json) {
    LabelingMode mode = LabelingMode.values.firstWhere(
      (e) => e.toString().split('.').last == json['labeling_mode'],
      orElse: () => LabelingMode.singleClassification, // 기본값 설정
    );

    dynamic labelData;
    if (mode == LabelingMode.singleClassification) {
      labelData = json['label'] != null ? SingleClassificationLabel.fromJson(json['label']) : null;
    } else if (mode == LabelingMode.multiClassification) {
      labelData = json['label'] != null ? MultiClassificationLabel.fromJson(json['label']) : null;
    } else if (mode == LabelingMode.segmentation) {
      labelData = json['label'] != null ? SingleClassSegmentationLabel.fromJson(json['label']) : null;
    }

    return LabelEntry(
      dataFilename: json['data_filename'] ?? 'unknown.json',
      dataPath: json['data_path'] ?? 'unknown_path',
      labelingMode: mode,
      label: labelData,
    );
  }
}
