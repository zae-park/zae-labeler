import 'base_label_model.dart';

/// ✅ Segmentation Label의 최상위 클래스
abstract class SegmentationLabelModel<T> extends LabelModel<T> {
  SegmentationLabelModel({required super.label, required super.labeledAt});

  // /// ✅ 기존 객체를 변경하여 새로운 `SegmentationLabel`을 반환
  // SegmentationLabel copyWith({DateTime? labeledAt, SegmentationData? label});
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  SingleClassSegmentationLabelModel({required super.labeledAt, required super.label});

  @override
  bool get isMultiClass => false;

  factory SingleClassSegmentationLabelModel.empty() => SingleClassSegmentationLabelModel(labeledAt: DateTime.now(), label: SegmentationData(segments: {}));

  SingleClassSegmentationLabelModel addPixel(int x, int y) => updateLabel(label.addPixel(x, y, label.segments.keys.first));
  SingleClassSegmentationLabelModel removePixel(int x, int y) => updateLabel(label.removePixel(x, y));

  @override
  SingleClassSegmentationLabelModel updateLabel(SegmentationData labelData) {
    return SingleClassSegmentationLabelModel(labeledAt: DateTime.now(), label: labelData);
  }

  @override
  bool isSelected(SegmentationData labelData) {
    return labelData.segments.values.any((segment) =>
        segment.indices.any((index) => label.segments.containsKey(segment.classLabel) && label.segments[segment.classLabel]!.indices.contains(index)));
  }

  SingleClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) {
    return SingleClassSegmentationLabelModel(labeledAt: labeledAt ?? this.labeledAt, label: label ?? this.label);
  }
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation) - 추후 업데이트
class MultiClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  MultiClassSegmentationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  factory MultiClassSegmentationLabelModel.empty() => MultiClassSegmentationLabelModel(labeledAt: DateTime.now(), label: SegmentationData(segments: {}));

  MultiClassSegmentationLabelModel addPixel(int x, int y, String classLabel) => updateLabel(label.addPixel(x, y, classLabel));
  MultiClassSegmentationLabelModel removePixel(int x, int y) => updateLabel(label.removePixel(x, y));

  @override
  MultiClassSegmentationLabelModel updateLabel(SegmentationData labelData) {
    return MultiClassSegmentationLabelModel(labeledAt: DateTime.now(), label: labelData);
  }

  /// ✅ 특정 픽셀 (x, y)이 특정 클래스 내에서 선택되었는지 확인
  @override
  bool isSelected(SegmentationData labelData) {
    return labelData.segments.values.any((segment) =>
        segment.indices.any((index) => label.segments.containsKey(segment.classLabel) && label.segments[segment.classLabel]!.indices.contains(index)));
  }

  MultiClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) {
    return MultiClassSegmentationLabelModel(labeledAt: labeledAt ?? this.labeledAt, label: label ?? this.label);
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

  /// ✅ Run-Length Encoding 적용 (RLE 압축)
  SegmentationData applyRunLengthEncoding() {
    Map<String, Segment> encodedSegments = {};

    for (var entry in segments.entries) {
      String classLabel = entry.key;
      Segment segment = entry.value;
      Set<(int, int)> encodedIndices = _runLengthEncode(segment.indices);
      encodedSegments[classLabel] = Segment(indices: encodedIndices, classLabel: classLabel);
    }

    return SegmentationData(segments: encodedSegments);
  }

  /// ✅ Run-Length Encoding 알고리즘
  static Set<(int, int)> _runLengthEncode(Set<(int, int)> indices) {
    List<(int, int)> sortedIndices = indices.toList()..sort((a, b) => a.$1.compareTo(b.$1)); // ✅ x좌표 기준 정렬
    Set<(int, int)> encoded = {};
    int? prevX;
    int count = 0;

    for (var (x, y) in sortedIndices) {
      if (prevX == null || prevX + count == x) {
        count++;
      } else {
        encoded.add((prevX, count));
        count = 1;
      }
      prevX = x;
    }

    if (prevX != null) {
      encoded.add((prevX, count));
    }

    return encoded;
  }

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
    Map<String, Segment> updatedSegments = Map.from(segments);

    if (updatedSegments.containsKey(classLabel)) {
      updatedSegments[classLabel] = updatedSegments[classLabel]!.addPixel(x, y);
    } else {
      updatedSegments[classLabel] = Segment(indices: {(x, y)}, classLabel: classLabel);
    }

    return SegmentationData(segments: updatedSegments);
  }

  /// ✅ 특정 픽셀을 삭제하는 메서드.
  SegmentationData removePixel(int x, int y) {
    Map<String, Segment> updatedSegments = {};

    segments.forEach((classLabel, segment) {
      Segment updatedSegment = segment.removePixel(x, y);
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
  final Set<(int, int)> indices;

  /// **세그먼트에 해당하는 클래스 라벨**
  /// - 해당 영역이 어떤 클래스에 속하는지 나타냄.
  /// - 예: `"car"`, `"road"`, `"tree"` 등.
  final String classLabel;

  Segment({required this.indices, required this.classLabel});

  /// ✅ Segment 객체를 JSON 형식으로 변환.
  Map<String, dynamic> toJson() => {'indices': SegmentRLECodec.encode(indices), 'class_label': classLabel};

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
    final indices = isRLE ? SegmentRLECodec.decode(List<Map<String, int>>.from(rawIndices)) : rawIndices.map((e) => (e['x'] as int, e['y'] as int)).toSet();

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

class SegmentRLECodec {
  /// ✅ 인코딩: 일반 좌표 Set → RLE 리스트
  static List<Map<String, int>> encode(Set<(int, int)> pixels) {
    final sorted = pixels.toList()..sort((a, b) => a.$2 == b.$2 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    final List<Map<String, int>> encoded = [];

    int? startX;
    int? y;
    int count = 0;

    for (final (x, currentY) in sorted) {
      if (startX == null || x != startX + count || currentY != y) {
        if (startX != null) {
          encoded.add({'x': startX, 'y': y!, 'count': count});
        }
        startX = x;
        y = currentY;
        count = 1;
      } else {
        count++;
      }
    }

    if (startX != null) {
      encoded.add({'x': startX, 'y': y!, 'count': count});
    }

    return encoded;
  }

  /// ✅ 디코딩: RLE 리스트 → Set<(x, y)>
  static Set<(int, int)> decode(List<Map<String, int>> rleList) {
    final Set<(int, int)> result = {};

    for (var rle in rleList) {
      int startX = rle['x']!;
      int y = rle['y']!;
      int count = rle['count'] ?? 1;

      for (int dx = 0; dx < count; dx++) {
        result.add((startX + dx, y));
      }
    }

    return result;
  }
}
