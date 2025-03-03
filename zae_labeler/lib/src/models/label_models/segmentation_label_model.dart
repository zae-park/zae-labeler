import 'label_model.dart';

/// ✅ Segmentation Label의 최상위 클래스
abstract class SegmentationLabel<T> extends LabelModel<T> {
  @override
  SegmentationData label;

  SegmentationLabel({required super.labeledAt, required this.label});

  SegmentationLabel copyWith({SegmentationData? label});
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabel extends SegmentationLabel {
  SingleClassSegmentationLabel({required super.labeledAt, required super.label});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label.toJson()};
  factory SingleClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SingleClassSegmentationLabel(labeledAt: json['labeled_at'], label: SegmentationData.fromJson(json['label_data']));
  factory SingleClassSegmentationLabel.empty() => SingleClassSegmentationLabel(labeledAt: '', label: SegmentationData(segments: []));
  @override
  SingleClassSegmentationLabel copyWith({SegmentationData? label}) {
    return SingleClassSegmentationLabel(labeledAt: DateTime.now().toIso8601String(), label: label ?? this.label);
  }
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation) - 추후 업데이트
class MultiClassSegmentationLabel extends SegmentationLabel {
  MultiClassSegmentationLabel({required super.labeledAt, required super.label});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label_data': label.toJson()};
  factory MultiClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassSegmentationLabel(labeledAt: json['labeled_at'], label: SegmentationData.fromJson(json['label_data']));
  factory MultiClassSegmentationLabel.empty() => MultiClassSegmentationLabel(labeledAt: '', label: SegmentationData(segments: []));
  @override
  MultiClassSegmentationLabel copyWith({SegmentationData? label}) {
    return MultiClassSegmentationLabel(labeledAt: DateTime.now().toIso8601String(), label: label ?? this.label);
  }
}

/// ✅ 세그멘테이션 데이터 구조를 저장하는 클래스.
/// - 여러 개의 `Segment` 객체를 포함하여 이미지 또는 데이터에서 특정 영역을 라벨링하는 데 사용됨.
/// - 각 `Segment`는 특정 클래스에 속하는 픽셀 좌표를 저장.
/// - `Segment` 내부의 `indices`는 `Set<List<int>>`으로 관리되어 중복 저장을 방지.
/// - `segments`는 `Map<String, Segment>`로 저장되어, 클래스별로 빠르게 접근 가능.
///
/// 📌 **사용 예시**
/// ```dart
/// SegmentationData segmentation = SegmentationData(segments: {
///   "car": Segment(indices: {[ [1, 2], [3, 4] ]}, classLabel: "car"),
///   "tree": Segment(indices: {[ [10, 11], [12, 13] ]}, classLabel: "tree"),
/// });
///
/// print(segmentation.toJson());
/// ```
///
/// ✅ **JSON 출력 예시**
/// ```json
/// {
///   "segments": {
///     "car": {"indices": [[1, 2], [3, 4]], "class_label": "car"},
///     "tree": {"indices": [[10, 11], [12, 13]], "class_label": "tree"}
///   }
/// }
/// ```
class SegmentationData {
  /// **세그먼트 맵 (Segment Map)**
  /// - 클래스 라벨(`String`)을 키(key)로 하여 `Segment` 객체를 저장.
  /// - 같은 클래스의 세그먼트가 자동으로 병합될 수 있도록 `Map<String, Segment>` 구조를 사용.
  final Map<String, Segment> segments;

  SegmentationData({required this.segments});

  /// ✅ JSON 변환 메서드
  /// - 각 `Segment` 객체를 JSON으로 변환하여 클래스 라벨별로 저장.
  Map<String, dynamic> toJson() => {'segments': segments.map((key, segment) => MapEntry(key, segment.toJson()))};

  /// ✅ JSON 데이터를 기반으로 `SegmentationData` 객체 생성.
  factory SegmentationData.fromJson(Map<String, dynamic> json) {
    return SegmentationData(
      segments: (json['segments'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Segment.fromJson(value)),
      ),
    );
  }

  /// ✅ 특정 클래스에 대해 픽셀 추가.
  SegmentationData addPixel(List<int> pixel, String classLabel) {
    Map<String, Segment> updatedSegments = Map.from(segments);

    if (updatedSegments.containsKey(classLabel)) {
      updatedSegments[classLabel] = updatedSegments[classLabel]!.addPixel(pixel);
    } else {
      updatedSegments[classLabel] = Segment(indices: {pixel}, classLabel: classLabel);
    }

    return SegmentationData(segments: updatedSegments);
  }

  /// ✅ 특정 픽셀을 삭제하는 메서드.
  SegmentationData removePixel(List<int> pixel) {
    Map<String, Segment> updatedSegments = {};

    segments.forEach((classLabel, segment) {
      Segment updatedSegment = segment.removePixel(pixel);
      if (updatedSegment.indices.isNotEmpty) {
        updatedSegments[classLabel] = updatedSegment;
      }
    });

    return SegmentationData(segments: updatedSegments);
  }
}

/// ✅ 개별 세그먼트(Segment)를 나타내는 클래스.
/// - 특정 영역(픽셀, 그리드 셀 또는 바운딩 박스)과 해당 영역의 클래스 정보를 저장.
/// - `indices`는 `Set<List<int>>` 형식으로 픽셀 또는 시계열 데이터의 위치를 관리.
/// - `Set`을 사용하여 탐색 속도를 높이고, 중복 데이터 저장을 방지.
///
/// 📌 **사용 예시**
/// ```dart
/// Segment segment = Segment(indices: {[ [5, 6], [7, 8] ]}, classLabel: "road");
/// print(segment.toJson());
/// ```
///
/// ✅ **JSON 출력 예시**
/// ```json
/// {
///   "indices": [[5, 6], [7, 8]],
///   "class_label": "road"
/// }
/// ```
class Segment {
  /// **세그먼트 영역의 인덱스 집합**
  /// - 이미지의 픽셀 인덱스 또는 시계열 데이터의 특정 위치를 저장.
  /// - 1D 데이터(시계열)은 `[index]` 형태로 저장.
  /// - 2D 데이터(이미지)는 `[x, y]` 형태로 저장.
  /// - `Set`을 사용하여 중복된 좌표를 자동으로 제거하고 탐색 속도를 향상.
  final Set<List<int>> indices;

  /// **세그먼트에 해당하는 클래스 라벨**
  /// - 해당 영역이 어떤 클래스에 속하는지 나타냄.
  /// - 예: `"car"`, `"road"`, `"tree"` 등.
  final String classLabel;

  Segment({required Set<List<int>> indices, required this.classLabel}) : indices = indices.toSet(); // ✅ 중복 제거 및 빠른 검색 가능하도록 Set 변환

  /// ✅ Segment 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'indices': indices.toList(), 'class_label': classLabel};

  /// ✅ JSON 데이터를 기반으로 Segment 객체를 생성하는 팩토리 메서드.
  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(indices: (json['indices']).map((row) => List<int>.from(row)).toList(), classLabel: json['class_label']);
  }

  /// ✅ 특정 픽셀을 빠르게 추가하는 메서드.
  /// - 중복된 픽셀은 자동으로 제거됨.
  Segment addPixel(List<int> newPixel) {
    Set<List<int>> updatedIndices = Set.from(indices)..add(newPixel);
    return Segment(indices: updatedIndices, classLabel: classLabel);
  }

  /// ✅ 특정 픽셀을 빠르게 삭제하는 메서드.
  Segment removePixel(List<int> targetPixel) {
    Set<List<int>> updatedIndices = Set.from(indices)..remove(targetPixel);
    return Segment(indices: updatedIndices, classLabel: classLabel);
  }
}
