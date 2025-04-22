import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';

void main() {
  group('SegmentationLabelModel', () {
    test('SingleClassSegmentationLabelModel pixel add/remove', () {
      final model =
          SingleClassSegmentationLabelModel.empty().copyWith(label: SegmentationData(segments: {'object': Segment(indices: {}, classLabel: 'object')}));

      final added = model.addPixel(1, 1, "sample");
      final removed = added.removePixel(1, 1);

      expect(added.label!.segments['sample']!.containsPixel(1, 1), isTrue);
      expect(removed.label!.segments['sample'], isNull);
    });

    test('MultiClassSegmentationLabelModel pixel add/remove', () {
      final model = MultiClassSegmentationLabelModel.empty().addPixel(2, 2, 'person').removePixel(2, 2);

      expect(model.label!.segments['person'], isNull);
    });
  });
}
