import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';

void main() {
  group('ClassificationLabelModel', () {
    test('SingleClassificationLabelModel isSelected works', () {
      final model = SingleClassificationLabelModel(dataId: 'test', label: 'cat', labeledAt: DateTime.now());
      expect(model.isSelected('cat'), isTrue);
      expect(model.isSelected('dog'), isFalse);
    });

    test('MultiClassificationLabelModel isSelected works', () {
      final model = MultiClassificationLabelModel(dataId: 'test', label: {'cat', 'dog'}, labeledAt: DateTime.now());
      expect(model.isSelected('dog'), isTrue);
      expect(model.isSelected('bird'), isFalse);
    });

    test('CrossClassificationLabelModel isSelected works', () {
      final model = CrossClassificationLabelModel(
        dataId: 'test',
        label: const CrossDataPair(sourceId: 'A', targetId: 'B', relation: 'Positive'),
        labeledAt: DateTime.now(),
      );

      expect(model.isSelected('Positive'), isTrue); // relation이 일치하면 true
      expect(model.isSelected('Negative'), isFalse); // relation이 다르면 false
    });

    test('CrossClassificationLabelModel toggleLabel updates relation', () {
      var model = CrossClassificationLabelModel(
        dataId: 'test',
        label: const CrossDataPair(sourceId: 'A', targetId: 'B', relation: 'Positive'),
        labeledAt: DateTime.now(),
      );

      model = model.toggleLabel('Negative') as CrossClassificationLabelModel;

      expect(model.label?.relation, 'Negative'); // relation이 Negative로 업데이트 되어야 함
      expect(model.isSelected('Negative'), isTrue);
      expect(model.isSelected('Positive'), isFalse);
    });

    test('CrossClassificationLabelModel toJson and fromJson work', () {
      final original = CrossClassificationLabelModel(
        dataId: 'test',
        label: const CrossDataPair(sourceId: 'A', targetId: 'B', relation: 'Positive'),
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
