// lib/src/models/label_entry.dart
import 'label_models/label_model.dart';
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
  singleClassification, // 단일 분류 (Single Classification) : 하나의 데이터에 대해 하나의 클래스를 지정
  multiClassification, // 다중 분류 (Multi Classification) : 하나의 데이터에 대해 여러 개의 클래스를 지정
  singleClassSegmentation, // 단일 클래스 세그멘테이션 (Single Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 단일 클래스를 지정
  multiClassSegmentation, // 다중 클래스 세그멘테이션 (Multi Class Segmentation) : 이미지 또는 시계열 데이터 내 특정 역역에 대해 다중 클래스를 지정
}

/// ✅ `LabelingMode`와 JSON 변환 클래스를 매핑하는 맵.
/// - 새로운 `LabelingMode`가 추가될 경우 이 맵에만 추가하면 됨.
final Map<LabelingMode, Function(Map<String, dynamic>)> labelFactory = {
  LabelingMode.singleClassification: (json) => SingleClassificationLabel.fromJson(json),
  LabelingMode.multiClassification: (json) => MultiClassificationLabel.fromJson(json),
  LabelingMode.singleClassSegmentation: (json) => SingleClassSegmentationLabel.fromJson(json),
  LabelingMode.multiClassSegmentation: (json) => MultiClassSegmentationLabel.fromJson(json),
};

/// ✅ `labelData`를 자동으로 생성하는 함수.
/// - `LabelingMode`에 따라 올바른 라벨 클래스 인스턴스를 생성함.
T? _createLabelData<T>(LabelingMode mode, Map<String, dynamic>? json) {
  if (json == null) return null;
  return labelFactory[mode]?.call(json) as T?;
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
class LabelEntry<T extends LabelModel> {
  final String dataFilename; // **데이터 파일 이름**
  final String dataPath; // **데이터 파일 경로**
  final LabelingMode labelingMode; // **해당 Entry가 속한 Labeling Mode**
  final T labelData; // **라벨 데이터 (T 타입)**

  LabelEntry({required this.dataFilename, required this.dataPath, required this.labelingMode, required this.labelData});

  /// ✅ `LabelingMode`에 따른 빈 LabelModel 반환 함수
  static LabelModel _getEmptyLabel(LabelingMode mode) {
    switch (mode) {
      case LabelingMode.singleClassification:
        return SingleClassificationLabel.empty();
      case LabelingMode.multiClassification:
        return MultiClassificationLabel.empty();
      case LabelingMode.singleClassSegmentation:
        return SingleClassSegmentationLabel.empty();
      case LabelingMode.multiClassSegmentation:
        return MultiClassSegmentationLabel.empty();
    }
  }

  /// **빈 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.empty(LabelingMode mode) {
    return LabelEntry(dataFilename: '', dataPath: '', labelingMode: mode, labelData: _getEmptyLabel(mode) as T);
  }

  /// **LabelEntry 객체를 JSON 형식으로 변환.**
  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'labeling_mode': labelingMode.toString().split('.').last,
        'label_data': labelData.toJson(),
      };

  /// **JSON 데이터를 기반으로 LabelEntry 객체를 생성하는 팩토리 메서드.**
  factory LabelEntry.fromJson(Map<String, dynamic> json) {
    LabelingMode mode = LabelingMode.values.firstWhere(
      (e) => e.toString().split('.').last == json['labeling_mode'],
      orElse: () => LabelingMode.singleClassification,
    );

    return LabelEntry(
      dataFilename: json['data_filename'] ?? 'unknown.json',
      dataPath: json['data_path'] ?? 'unknown_path',
      labelingMode: mode,
      labelData: _createLabelData(mode, json['label_data']),
    );
  }
}
