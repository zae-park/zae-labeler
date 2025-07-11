import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/features/label/models/sub_models/segmentation_label_model.dart';

void main() {
  group('LabelModel', () {
    test('SingleClassificationLabelModel implements LabelModel', () {
      final model = SingleClassificationLabelModel(dataId: 'test', label: 'label', labeledAt: DateTime(2024, 1, 1));
      expect(model.label, equals('label'));
      expect(model.isMultiClass, isFalse);
    });

    test('MultiClassSegmentationLabelModel implements LabelModel', () {
      final model = MultiClassSegmentationLabelModel.empty();
      expect(model.isMultiClass, isTrue);
    });
  });
}
