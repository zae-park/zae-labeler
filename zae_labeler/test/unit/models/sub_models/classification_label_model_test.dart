import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/sub_models/classification_label_model.dart';

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

    test('CrossClassificationLabelModel toJson and fromJson work', () {
      final original = CrossClassificationLabelModel(
        dataId: 'test',
        label: CrossDataPair(sourceId: 'A', targetId: 'B', relation: 'Positive'),
        labeledAt: DateTime.now(),
      );

      final json = original.toJson();
      final recreated = CrossClassificationLabelModel.fromJson(json);

      expect(recreated.label?.sourceId, 'A');
      expect(recreated.label?.targetId, 'B');
      expect(recreated.label?.relation, 'Positive');
    });
  });
}
