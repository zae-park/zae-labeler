// lib/src/core/models/label/segmentation_data.dart

import '../../../utils/run_length_codec.dart';

/// ✅ 세그멘테이션 데이터 구조를 저장하는 클래스.
/// - 여러 개의 `Segment` 객체를 포함하여 이미지 또는 데이터에서 특정 영역을 라벨링하는 데 사용됨.
/// - 각 `Segment`는 특정 클래스에 속하는 픽셀 좌표를 저장.
/// - `Segment` 내부의 `indices`는 `Set<(int, int)>`으로 관리되어 중복 저장을 방지.
/// - `segments`는 `Map<String, Segment>`로 저장되어, 클래스별로 빠르게 접근 가능.
///
/// 📌 **사용 예시**
/// ```dart
/// SegmentationData segmentation = SegmentationData(segments: {
///   "car": Segment(indices: {(1, 2), (3, 4)}, classLabel: "car"),
///   "tree": Segment(indices: {(10, 11), (12, 13)}, classLabel: "tree"),
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

  const SegmentationData({required this.segments});

  static const SegmentationData empty = SegmentationData(segments: {});

  bool get isEmpty => segments.isEmpty || segments.values.every((s) => s.indices.isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// ✅ JSON 변환 메서드
  Map<String, dynamic> toJson() => {'segments': segments.map((key, segment) => MapEntry(key, segment.toJson()))};

  /// ✅ JSON 데이터를 기반으로 `SegmentationData` 객체 생성.
  factory SegmentationData.fromJson(Map<String, dynamic> json) {
    final segs = json['segments'];
    if (segs is! Map) {
      // 방어: 잘못된 구조면 빈 데이터로 복구
      return const SegmentationData(segments: {});
    }
    final map = <String, Segment>{};
    segs.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        map[key] = Segment.fromJson(value);
      } else if (value is Map) {
        map[key] = Segment.fromJson(Map<String, dynamic>.from(value));
      }
      // 그 외 타입은 skip (유효성 방어)
    });
    return SegmentationData(segments: map);
  }

  /// ✅ 특정 클래스에 대해 픽셀 추가.
  SegmentationData addPixel(int x, int y, String classLabel) {
    final updated = segments[classLabel]?.addPixel(x, y) ?? Segment(indices: {(x, y)}, classLabel: classLabel);
    return SegmentationData(segments: {...segments, classLabel: updated});
  }

  /// ✅ 여러 픽셀을 한 번에 추가(편의)
  SegmentationData addPixels(Iterable<(int, int)> coords, String classLabel) {
    var seg = segments[classLabel] ?? Segment(indices: const {}, classLabel: classLabel);
    for (final (x, y) in coords) {
      seg = seg.addPixel(x, y);
    }
    return SegmentationData(segments: {...segments, classLabel: seg});
  }

  /// ✅ 특정 픽셀을 삭제하는 메서드.
  SegmentationData removePixel(int x, int y) {
    final updatedSegments = <String, Segment>{};
    for (final entry in segments.entries) {
      final seg = entry.value.containsPixel(x, y) ? entry.value.removePixel(x, y) : entry.value;
      if (seg.indices.isNotEmpty) {
        updatedSegments[entry.key] = seg;
      }
    }
    return SegmentationData(segments: updatedSegments);
  }

  /// ✅ 여러 픽셀을 한 번에 삭제(편의)
  SegmentationData removePixels(Iterable<(int, int)> coords) {
    final updated = <String, Segment>{};
    for (final entry in segments.entries) {
      var seg = entry.value;
      for (final (x, y) in coords) {
        if (seg.containsPixel(x, y)) seg = seg.removePixel(x, y);
      }
      if (seg.indices.isNotEmpty) updated[entry.key] = seg;
    }
    return SegmentationData(segments: updated);
  }
}

/// ✅ 개별 세그먼트(Segment)를 나타내는 클래스.
/// - 특정 영역(픽셀, 그리드 셀 또는 바운딩 박스)과 해당 영역의 클래스 정보를 저장.
/// - `indices`는 `Set<(int, int)>` 형식으로 픽셀 또는 시계열 데이터의 위치를 관리.
/// - `Set`을 사용하여 탐색 속도를 높이고, 중복 데이터 저장을 방지.
///
/// 📌 **사용 예시**
/// ```dart
/// Segment segment = Segment(indices: {(5, 6), (7, 8)}, classLabel: "road");
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
  /// - 2D 데이터(이미지)는 `(x, y)` 튜플로 저장.
  /// - 1D 데이터(시계열) 확장 시 `(t, 0)` 같은 규약을 사용해도 됩니다.
  final Set<(int, int)> indices;

  /// **세그먼트에 해당하는 클래스 라벨**
  final String classLabel;

  const Segment({required this.indices, required this.classLabel});

  /// ✅ Segment 객체를 JSON 형식으로 변환.
  /// - 내부는 RLE(런렝스)로 압축하여 저장(예: 모바일/웹 전송량 절감)
  Map<String, dynamic> toJson() => {'indices': RunLengthCodec.encode(indices), 'class_label': classLabel};

  @override
  int get hashCode => classLabel.hashCode ^ indices.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment && classLabel == other.classLabel && indices.length == other.indices.length && indices.containsAll(other.indices);

  /// ✅ JSON → Segment
  /// - RLE/비RLE 모두 수용(레거시 호환)
  factory Segment.fromJson(Map<String, dynamic> json) {
    final raw = json['indices'];
    Set<(int, int)> idx = const <(int, int)>{};

    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;

      // 1) RLE: [{x:.., y:.., count:..}, ...]
      if (first is Map && first.containsKey('count')) {
        idx = RunLengthCodec.decode(List<Map<String, dynamic>>.from(raw));
      }
      // 2) 좌표 객체 배열: [{x:.., y:..}, ...]
      else if (first is Map && (first.containsKey('x') || first.containsKey('y'))) {
        idx = raw
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .map<(int, int)>((m) => ((m['x'] as num).toInt(), (m['y'] as num).toInt()))
            .toSet();
      }
      // 3) 2원소 배열: [[x,y], [x,y], ...]
      else if (first is List && first.length == 2) {
        idx = raw.whereType<List>().where((e) => e.length == 2).map<(int, int)>((e) => ((e[0] as num).toInt(), (e[1] as num).toInt())).toSet();
      }
      // 그 외 포맷은 무시(방어)
    }

    final label = json['class_label'];
    return Segment(indices: idx, classLabel: label is String ? label : '');
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
  bool containsPixel(int x, int y) => indices.contains((x, y));
}
