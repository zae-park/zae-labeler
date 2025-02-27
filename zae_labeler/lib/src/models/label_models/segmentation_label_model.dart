import 'label_model.dart';

/// ✅ Segmentation Label의 최상위 클래스
abstract class SegmentationLabel extends LabelModel {
  SegmentationData labelData;

  SegmentationLabel({required super.labeledAt, required this.labelData});
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabel extends SegmentationLabel {
  SingleClassSegmentationLabel({required super.labeledAt, required super.labelData});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label_data': labelData.toJson()};

  factory SingleClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SingleClassSegmentationLabel(labeledAt: json['labeled_at'], labelData: SegmentationData.fromJson(json['label_data']));
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation) - 추후 업데이트
class MultiClassSegmentationLabel extends SegmentationLabel {
  MultiClassSegmentationLabel({required super.labeledAt, required super.labelData});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label_data': labelData.toJson()};

  factory MultiClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassSegmentationLabel(labeledAt: json['labeled_at'], labelData: SegmentationData.fromJson(json['label_data']));
}

/// ✅ 세그멘테이션 데이터 구조를 저장하는 클래스.
/// - 여러 개의 `Segment` 객체를 포함하여 이미지 또는 데이터에서 특정 영역을 라벨링하는 데 사용됨.
/// - 각 `Segment`는 픽셀 좌표 또는 인덱스를 기반으로 특정 영역을 나타냄.
///
/// 📌 **사용 예시**
/// ```dart
/// SegmentationData segmentation = SegmentationData(segments: [
///   Segment(indices: [1, 2, 3, 4], classLabel: "car"),
///   Segment(indices: [10, 11, 12, 13], classLabel: "tree"),
/// ]);
///
/// print(segmentation.toJson());
/// ```
///
/// ✅ **JSON 출력 예시**
/// ```json
/// {
///   "segments": [
///     {"indices": [1, 2, 3, 4], "class_label": "car"},
///     {"indices": [10, 11, 12, 13], "class_label": "tree"}
///   ]
/// }
/// ```
class SegmentationData {
  /// **세그먼트 리스트 (Segment List)**
  /// - 이미지 또는 데이터에서 특정 영역을 나타내는 `Segment` 객체 리스트.
  /// - 각 `Segment`는 특정 클래스 라벨을 가지고 있으며, `indices`를 통해 해당 영역을 지정.
  List<Segment> segments;

  SegmentationData({required this.segments});

  /// SegmentationData 객체를 JSON 형식으로 변환.
  /// - 각 `Segment` 객체를 JSON으로 변환하여 리스트로 저장.
  Map<String, dynamic> toJson() => {'segments': segments.map((s) => s.toJson()).toList()};

  /// JSON 데이터를 기반으로 SegmentationData 객체를 생성하는 팩토리 메서드.
  factory SegmentationData.fromJson(Map<String, dynamic> json) => SegmentationData(
        segments: (json['segments'] as List).map((s) => Segment.fromJson(s)).toList(),
      );
}

/// ✅ 개별 세그먼트(Segment)를 나타내는 클래스.
/// - 특정 영역(픽셀, 그리드 셀 또는 바운딩 박스)과 해당 영역의 클래스 정보를 저장.
/// - `indices` 리스트를 사용하여 해당 영역의 픽셀 또는 인덱스를 정의.
///
/// 📌 **사용 예시**
/// ```dart
/// Segment segment = Segment(indices: [5, 6, 7, 8], classLabel: "road");
/// print(segment.toJson());
/// ```
///
/// ✅ **JSON 출력 예시**
/// ```json
/// {
///   "indices": [5, 6, 7, 8],
///   "class_label": "road"
/// }
/// ```
class Segment {
  /// **세그먼트 영역의 인덱스 리스트**
  /// - 이미지의 픽셀 인덱스 또는 시계열 데이터의 특정 위치를 저장.
  /// - 예: `[3, 4, 5, 6]` → 이미지에서 픽셀 3, 4, 5, 6이 특정 클래스에 해당함.
  List<int> indices;

  /// **세그먼트에 해당하는 클래스 라벨**
  /// - 해당 영역이 어떤 클래스에 속하는지 나타냄.
  /// - 예: `"car"`, `"road"`, `"tree"` 등.
  String classLabel;

  Segment({required this.indices, required this.classLabel});

  /// Segment 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'indices': indices, 'class_label': classLabel};

  /// JSON 데이터를 기반으로 Segment 객체를 생성하는 팩토리 메서드.
  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        indices: List<int>.from(json['indices']),
        classLabel: json['class_label'],
      );
}
