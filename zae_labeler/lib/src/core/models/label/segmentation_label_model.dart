import 'label_types.dart';
import 'base_label_model.dart';
import '../../../utils/run_length_codec.dart';

/// ✅ Segmentation Label의 최상위 클래스
abstract class SegmentationLabelModel<T> extends LabelModel<T> {
  SegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});
  // SegmentationLabelModel updateLabel(SegmentationData labelData);
  SegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label});

  @override
  LabelingMode get mode;
  @override
  bool get isMultiClass;
  @override
  bool get isLabeled;

  // SegmentationLabelModel<T> addPixel(int x, int y, String classLabel);
  // SegmentationLabelModel<T> removePixel(int x, int y);
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  SingleClassSegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode => LabelingMode.singleClassSegmentation;

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'label': label!.toJson(), 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory SingleClassSegmentationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassSegmentationLabelModel(
        dataId: json['data_id'], dataPath: json['data_path'], label: SegmentationData.fromJson(json['label']), labeledAt: DateTime.parse(json['labeled_at']));
  }

  @override
  factory SingleClassSegmentationLabelModel.empty() =>
      SingleClassSegmentationLabelModel(dataId: '', dataPath: null, label: SegmentationData(segments: {}), labeledAt: DateTime.fromMillisecondsSinceEpoch(0));

  // @override
  // SingleClassSegmentationLabelModel addPixel(int x, int y, String classLabel) => updateLabel(label!.addPixel(x, y, classLabel));
  // @override
  // SingleClassSegmentationLabelModel removePixel(int x, int y) => updateLabel(label!.removePixel(x, y));

  // @override
  // SingleClassSegmentationLabelModel updateLabel(SegmentationData labelData) =>
  //     SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: labelData, labeledAt: DateTime.now());

  // bool isSelected(SegmentationData labelData) {
  //   if (label!.segments.isEmpty || labelData.segments.isEmpty) return false;
  //   final labelClass = label!.segments.keys.first;
  //   return labelData.segments[labelClass]?.indices.any((index) => label!.segments[labelClass]?.indices.contains(index) ?? false) ?? false;
  // }

  @override
  SingleClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) =>
      SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt ?? this.labeledAt, label: label ?? this.label);
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation) - 추후 업데이트
class MultiClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  MultiClassSegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode => LabelingMode.multiClassSegmentation;

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'label': label!.toJson(), 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory MultiClassSegmentationLabelModel.fromJson(Map<String, dynamic> json) => MultiClassSegmentationLabelModel(
      dataId: json['data_id'], dataPath: json['data_path'], label: SegmentationData.fromJson(json['label']), labeledAt: DateTime.parse(json['labeled_at']));

  @override
  factory MultiClassSegmentationLabelModel.empty() =>
      MultiClassSegmentationLabelModel(dataId: '', dataPath: null, label: SegmentationData(segments: {}), labeledAt: DateTime.fromMillisecondsSinceEpoch(0));

  @override
  MultiClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) =>
      MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt ?? this.labeledAt, label: label ?? this.label);

  // @override
  // MultiClassSegmentationLabelModel addPixel(int x, int y, String classLabel) => updateLabel(label!.addPixel(x, y, classLabel));
  // @override
  // MultiClassSegmentationLabelModel removePixel(int x, int y) => updateLabel(label!.removePixel(x, y));

  // @override
  // MultiClassSegmentationLabelModel updateLabel(SegmentationData labelData) =>
  //     MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: labelData, labeledAt: DateTime.now());

  // bool isSelected(SegmentationData other) => other.segments.entries.any((entry) {
  //       final targetSegment = label!.segments[entry.key];
  //       return targetSegment != null && entry.value.indices.any((index) => targetSegment.indices.contains(index));
  //     });
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

  bool get isEmpty => segments.isEmpty || segments.values.every((s) => s.indices.isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// ✅ JSON 변환 메서드
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
  SegmentationData addPixel(int x, int y, String classLabel) {
    Segment updated = segments[classLabel]?.addPixel(x, y) ?? Segment(indices: {(x, y)}, classLabel: classLabel);
    return SegmentationData(segments: {...segments, classLabel: updated});
  }

  /// ✅ 특정 픽셀을 삭제하는 메서드.
  SegmentationData removePixel(int x, int y) {
    final updatedSegments = {
      for (final entry in segments.entries)
        if (entry.value.containsPixel(x, y)) entry.key: entry.value.removePixel(x, y) else entry.key: entry.value,
    }..removeWhere((_, segment) => segment.indices.isEmpty);

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
  final Set<(int, int)> indices;

  /// **세그먼트에 해당하는 클래스 라벨**
  /// - 해당 영역이 어떤 클래스에 속하는지 나타냄.
  /// - 예: `"car"`, `"road"`, `"tree"` 등.
  final String classLabel;

  Segment({required this.indices, required this.classLabel});

  /// ✅ Segment 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'indices': RunLengthCodec.encode(indices), 'class_label': classLabel};

  @override
  int get hashCode => classLabel.hashCode ^ indices.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment && classLabel == other.classLabel && indices.length == other.indices.length && indices.containsAll(other.indices);

  /// ✅ JSON 데이터를 기반으로 Segment 객체를 생성하는 팩토리 메서드.
  factory Segment.fromJson(Map<String, dynamic> json) {
    final rawIndices = json['indices'] as List;
    final isRLE = rawIndices.isNotEmpty && rawIndices.first.containsKey('count');
    final indices = isRLE ? RunLengthCodec.decode(List<Map<String, dynamic>>.from(rawIndices)) : rawIndices.map((e) => (e['x'] as int, e['y'] as int)).toSet();

    return Segment(indices: indices, classLabel: json['class_label']);
  }

  Segment addPixel(int x, int y) {
    if (indices.contains((x, y))) return this;
    final updated = Set<(int, int)>.from(indices)..add((x, y));
    return Segment(indices: updated, classLabel: classLabel);
  }

  Segment removePixel(int x, int y) {
    if (!indices.contains((x, y))) return this;
    final updated = Set<(int, int)>.from(indices)..remove((x, y));
    return Segment(indices: updated, classLabel: classLabel);
  }

  /// ✅ 특정 픽셀이 해당 클래스에 속해 있는지 확인
  bool containsPixel(int x, int y) {
    return indices.contains((x, y));
  }
}
