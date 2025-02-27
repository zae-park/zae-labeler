// lib/src/models/label_entry.dart

/*
이 파일은 데이터 파일에 대한 라벨 정보를 정의합니다.
LabelEntry 클래스는 단일 분류, 다중 분류, 세그멘테이션과 같은 다양한 라벨링 작업을 지원합니다.
라벨 엔트리와 관련된 JSON 직렬화 및 역직렬화를 포함합니다.
*/

/// 특정 데이터 파일에 대한 라벨 정보를 나타내는 클래스.
/// - 단일 분류(Single Classification), 다중 분류(Multi Classification), 세그멘테이션(Segmentation) 등의 라벨을 저장할 수 있음.
class LabelEntry {
  String dataFilename; // 데이터 파일 이름
  String dataPath; // 데이터 파일 경로
  SingleClassificationLabel? singleClassification; // 단일 분류 라벨
  MultiClassificationLabel? multiClassification; // 다중 분류 라벨
  SegmentationLabel? segmentation; // 세그멘테이션 라벨

  LabelEntry({required this.dataFilename, required this.dataPath, this.singleClassification, this.multiClassification, this.segmentation});

  /// 빈 LabelEntry 객체를 생성하는 팩토리 메서드.
  factory LabelEntry.empty() => LabelEntry(dataFilename: '', dataPath: '', singleClassification: null, multiClassification: null, segmentation: null);

  /// LabelEntry 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'single_classification': singleClassification?.toJson(),
        'multi_classification': multiClassification?.toJson(),
        'segmentation': segmentation?.toJson(),
      };

  /// JSON 데이터를 기반으로 LabelEntry 객체를 생성하는 팩토리 메서드.
  factory LabelEntry.fromJson(Map<String, dynamic> json) => LabelEntry(
        dataFilename: json['data_filename'] ?? 'unknown.json',
        dataPath: json['data_path'] ?? 'unknown_path',
        singleClassification: json['single_classification'] != null ? SingleClassificationLabel.fromJson(json['single_classification']) : null,
        multiClassification: json['multi_classification'] != null ? MultiClassificationLabel.fromJson(json['multi_classification']) : null,
        segmentation: json['segmentation'] != null ? SegmentationLabel.fromJson(json['segmentation']) : null,
      );
}

/// ✅ 단일 분류(Single Classification) 라벨을 나타내는 클래스.
/// - 특정 시간에 하나의 클래스 라벨이 부여됨.
class SingleClassificationLabel {
  String labeledAt; // 라벨이 부여된 시간 (ISO 8601 형식)
  String label; // 선택된 라벨 (클래스)

  SingleClassificationLabel({required this.labeledAt, required this.label});

  /// SingleClassificationLabel 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label};

  /// JSON 데이터를 기반으로 SingleClassificationLabel 객체를 생성하는 팩토리 메서드.
  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) => SingleClassificationLabel(labeledAt: json['labeled_at'], label: json['label']);
}

/// ✅ 다중 분류(Multi Classification) 라벨을 나타내는 클래스.
/// - 특정 시간에 여러 개의 클래스 라벨이 부여될 수 있음.
class MultiClassificationLabel {
  String labeledAt; // 라벨이 부여된 시간 (ISO 8601 형식)
  List<String> labels; // 선택된 다중 라벨 리스트

  MultiClassificationLabel({required this.labeledAt, required this.labels});

  /// MultiClassificationLabel 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'labels': labels};

  /// JSON 데이터를 기반으로 MultiClassificationLabel 객체를 생성하는 팩토리 메서드.
  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassificationLabel(labeledAt: json['labeled_at'], labels: List<String>.from(json['labels']));
}

/// ✅ 세그멘테이션(Segmentation) 라벨을 나타내는 클래스.
/// - 이미지나 시퀀스 데이터에서 특정 영역(픽셀 또는 바운딩 박스 등)을 분할하여 라벨링.
class SegmentationLabel {
  String labeledAt; // 라벨이 부여된 시간 (ISO 8601 형식)
  SegmentationData label; // 세그멘테이션 데이터

  SegmentationLabel({required this.labeledAt, required this.label});

  /// SegmentationLabel 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label.toJson()};

  /// JSON 데이터를 기반으로 SegmentationLabel 객체를 생성하는 팩토리 메서드.
  factory SegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SegmentationLabel(labeledAt: json['labeled_at'], label: SegmentationData.fromJson(json['label']));
}

/// ✅ 세그멘테이션(Segmentation) 데이터를 저장하는 클래스.
/// - 여러 개의 세그먼트(Segment)를 포함하여 이미지 또는 데이터의 특정 영역을 저장함.
class SegmentationData {
  List<Segment> segments; // 개별 세그먼트 목록

  SegmentationData({required this.segments});

  /// SegmentationData 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'segments': segments.map((s) => s.toJson()).toList()};

  /// JSON 데이터를 기반으로 SegmentationData 객체를 생성하는 팩토리 메서드.
  factory SegmentationData.fromJson(Map<String, dynamic> json) => SegmentationData(
        segments: (json['segments'] as List).map((s) => Segment.fromJson(s)).toList(),
      );
}

/// ✅ 개별 세그먼트(Segment)를 나타내는 클래스.
/// - 특정 영역(픽셀 또는 바운딩 박스)과 해당 영역에 대한 클래스 정보를 저장함.
class Segment {
  List<int> indices; // 픽셀 또는 영역 인덱스 (예: 이미지의 픽셀 좌표)
  String classLabel; // 이 세그먼트에 할당된 클래스 라벨

  Segment({required this.indices, required this.classLabel});

  /// Segment 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'indices': indices, 'class_label': classLabel};

  /// JSON 데이터를 기반으로 Segment 객체를 생성하는 팩토리 메서드.
  factory Segment.fromJson(Map<String, dynamic> json) => Segment(indices: List<int>.from(json['indices']), classLabel: json['class_label']);
}
