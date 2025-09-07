import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/segmentation_data.dart';

/// Additional tests for [SegmentationData] focusing on multi‑class operations
/// and handling of duplicate coordinates.
void main() {
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
