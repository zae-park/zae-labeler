import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';

void main() {
  group('ClassificationLabelModel', () {
    test('SingleClassificationLabelModel isSelected works', () {
      final model = SingleClassificationLabelModel(dataId: 'test', label: 'cat', labeledAt: DateTime.now());
      expect(model.label == 'cat', isTrue);
      expect(model.label == 'dog', isFalse);
    });

    test('MultiClassificationLabelModel isSelected works', () {
      final model = MultiClassificationLabelModel(dataId: 'test', label: {'cat', 'dog'}, labeledAt: DateTime.now());
      expect(model.label?.contains('dog'), isTrue);
      expect(model.label?.contains('bird'), isFalse);
    });

    test('CrossClassificationLabelModel isSelected works', () {
      final model = CrossClassificationLabelModel(
        dataId: 'test',
        label: CrossDataPair(sourceId: 'A', targetId: 'B', relation: 'Positive'),
        labeledAt: DateTime.now(),
      );

      expect(model.label?.relation == 'Positive', isTrue); // relation이 일치하면 true
      expect(model.label?.relation == 'Negative', isFalse); // relation이 다르면 false
    });
  });
}
