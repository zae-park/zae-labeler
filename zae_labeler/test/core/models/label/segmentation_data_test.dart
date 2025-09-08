import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/segmentation_data.dart';

void main() {
  group('SegmentationData JSON round‑trip', () {
    test('toJson and fromJson should preserve segments', () {
      final data = SegmentationData(
        segments: {
          'cat': Segment(indices: {(1, 2), (3, 4)}, classLabel: 'cat'),
          'dog': Segment(indices: {(5, 6)}, classLabel: 'dog'),
        },
      );

      final json = data.toJson();
      expect(json['segments'], isA<Map>());
      // Ensure each entry contains expected keys
      expect(json['segments']['cat'], containsPair('class_label', 'cat'));
      expect(json['segments']['dog'], containsPair('class_label', 'dog'));

      final roundTrip = SegmentationData.fromJson(json);
      // round‑trip should yield equivalent structure
      expect(roundTrip.segments.keys.toSet(), equals(data.segments.keys.toSet()));
      // each segment should be equal via operator ==
      for (final entry in data.segments.entries) {
        final key = entry.key;
        expect(roundTrip.segments[key], equals(entry.value));
      }
    });

    test('fromJson should fallback to empty on invalid structure', () {
      final invalid = {'segments': 123};
      final data = SegmentationData.fromJson(invalid);
      expect(data.segments, isEmpty);
      expect(data.isEmpty, isTrue);
    });
  });

  group('SegmentationData pixel operations', () {
    test('addPixel should add and merge segments by class', () {
      final data = SegmentationData(segments: {});
      final after = data.addPixel(1, 1, 'road');
      expect(after.segments.containsKey('road'), isTrue);
      expect(after.segments['road']!.indices, contains((1, 1)));

      // adding another pixel of same class merges into same segment
      final merged = after.addPixel(2, 2, 'road');
      expect(merged.segments['road']!.indices, containsAll({(1, 1), (2, 2)}));
      // original instance remains unchanged (immutability)
      expect(data.segments, isEmpty);
    });

    test('addPixels should add multiple coordinates', () {
      final data = SegmentationData(segments: {});
      final coords = <(int, int)>{(0, 0), (1, 1), (2, 2)};
      final updated = data.addPixels(coords, 'sky');
      expect(updated.segments['sky']!.indices.length, equals(coords.length));
      expect(updated.segments['sky']!.indices, containsAll(coords));
    });

    test('removePixel should remove a specific pixel and drop empty segments', () {
      final data = SegmentationData(
        segments: {
          'grass': Segment(indices: {(1, 1), (2, 2)}, classLabel: 'grass'),
        },
      );
      final removed = data.removePixel(2, 2);
      expect(removed.segments['grass']!.indices, contains((1, 1)));
      expect(removed.segments['grass']!.indices, isNot(contains((2, 2))));
      // removing last pixel should remove the entire segment
      final removedAll = removed.removePixel(1, 1);
      expect(removedAll.segments.containsKey('grass'), isFalse);
    });

    test('removePixels should remove multiple pixels', () {
      final data = SegmentationData(
        segments: {
          'car': Segment(indices: {(1, 2), (3, 4), (5, 6)}, classLabel: 'car'),
        },
      );
      final removed = data.removePixels({(1, 2), (3, 4)});
      expect(removed.segments['car']!.indices, equals({(5, 6)}));
    });
  });

  group('Segment JSON & equality', () {
    test('Segment toJson uses RLE and equality compares by indices and class', () {
      final seg = Segment(indices: {(1, 2), (1, 3), (1, 4)}, classLabel: 'lane');
      final json = seg.toJson();
      expect(json['class_label'], equals('lane'));
      // decode back
      final decoded = Segment.fromJson({'indices': json['indices'], 'class_label': json['class_label']});
      expect(decoded, equals(seg));
      // equality should ignore order
      final seg2 = Segment(indices: {(1, 4), (1, 2), (1, 3)}, classLabel: 'lane');
      expect(seg2, equals(seg));
    });
  });

  /// Additional tests for [SegmentationData] focusing on multi‑class operations
  /// and handling of duplicate coordinates.
  group('SegmentationData multi‑class and duplicate handling', () {
    test('addPixels deduplicates coordinates and keeps class separation', () {
      // start with empty data
      final data = SegmentationData(segments: {});
      // add duplicates for class 'car'
      final carData = data.addPixels({(1, 1), (1, 1), (2, 2)}, 'car');
      // duplicates should be removed
      expect(carData.segments['car']!.indices.length, equals(2));
      expect(carData.segments['car']!.indices, containsAll({(1, 1), (2, 2)}));
      // add different class with overlapping coordinate
      final treeData = carData.addPixels({(1, 1), (3, 3)}, 'tree');
      expect(treeData.segments['tree']!.indices.length, equals(2));
      expect(treeData.segments['tree']!.indices, containsAll({(1, 1), (3, 3)}));
      // original class coordinates remain unchanged
      expect(treeData.segments['car']!.indices, containsAll({(1, 1), (2, 2)}));
    });

    test('removePixel on non‑existent coordinate leaves data unchanged', () {
      final initial = SegmentationData(
        segments: {
          'road': Segment(indices: {(4, 4)}, classLabel: 'road'),
        },
      );
      final removed = initial.removePixel(5, 5);
      // nothing should change
      expect(removed.segments, equals(initial.segments));
    });
  });
}
