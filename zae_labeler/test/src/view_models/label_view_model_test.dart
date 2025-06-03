import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/view_models/sub_view_models/segmentation_label_view_model.dart';

import '../../mocks/mock_storage_helper.dart';
import '../../mocks/mock_label_repository.dart';

void main() {
  group('SegmentationLabelViewModel', () {
    late SegmentationLabelViewModel labelVM;

    setUp(() {
      labelVM = SegmentationLabelViewModel(
        projectId: 'proj-123',
        dataId: 'data-001',
        dataFilename: 'image.png',
        dataPath: '/path/image.png',
        mode: LabelingMode.multiClassSegmentation,
        labelModel: MultiClassSegmentationLabelModel.empty(),
        storageHelper: MockStorageHelper(),
      );
    });

    test('initial label is empty', () {
      final label = labelVM.labelModel.label as SegmentationData;
      expect(label.segments, isEmpty);
    });

    test('addPixel adds pixel to the correct class', () {
      labelVM.addPixel(10, 20, 'tree');
      final label = labelVM.labelModel.label as SegmentationData;

      expect(label.segments.containsKey('tree'), isTrue);
      expect(label.segments['tree']!.indices.contains((10, 20)), isTrue);
    });

    test('removePixel removes pixel from the correct class', () {
      labelVM.addPixel(5, 5, 'sky');
      labelVM.removePixel(5, 5);

      final label = labelVM.labelModel.label as SegmentationData;
      expect(label.segments['sky']?.indices.contains((5, 5)), isNull);
    });

    test('updateLabel replaces the labelModel content', () {
      final newLabel = SegmentationData(segments: {
        'road': Segment(indices: {(1, 2), (3, 4)}, classLabel: 'road'),
      });

      labelVM.updateLabel(newLabel);

      final label = labelVM.labelModel.label as SegmentationData;
      expect(label.segments['road']?.indices.length, equals(2));
      expect(label.segments['road']!.indices.contains((3, 4)), isTrue);
    });

    test('updateLabel throws error on invalid data', () {
      expect(() => labelVM.updateLabel('invalid'), throwsA(isA<ArgumentError>()));
    });
  });
}
