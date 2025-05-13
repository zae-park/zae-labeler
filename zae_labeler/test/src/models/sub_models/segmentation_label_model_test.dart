import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';

void main() {
  group('SegmentationLabelModel', () {
    test('SingleClassSegmentationLabelModel pixel add/remove and status', () {
      final model = SingleClassSegmentationLabelModel.empty();

      expect(model.isLabeled, isFalse);

      final added = model.addPixel(1, 1, "sample");
      expect(added.label?.segments['sample']!.containsPixel(1, 1), isTrue);
      expect(added.isLabeled, isTrue);

      final removed = added.removePixel(1, 1);
      expect(removed.label?.segments['sample'], isNull);
      expect(removed.isLabeled, isFalse);
    });

    test('MultiClassSegmentationLabelModel pixel add/remove and status', () {
      final model = MultiClassSegmentationLabelModel.empty();

      final added = model.addPixel(2, 2, 'person');
      expect(added.label?.segments['person']?.containsPixel(2, 2), isTrue);
      expect(added.isLabeled, isTrue);

      final removed = added.removePixel(2, 2);
      expect(removed.label?.segments['person'], isNull);
      expect(removed.isLabeled, isFalse);
    });
  });
}
