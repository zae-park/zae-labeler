import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';

void main() {
  group('ClassificationLabelModel', () {
    test('SingleClassificationLabelModel isSelected works', () {
      final model = SingleClassificationLabelModel(label: 'cat', labeledAt: DateTime.now());
      expect(model.isSelected('cat'), isTrue);
      expect(model.isSelected('dog'), isFalse);
    });

    test('MultiClassificationLabelModel isSelected works', () {
      final model = MultiClassificationLabelModel(label: ['cat', 'dog'], labeledAt: DateTime.now());
      expect(model.isSelected(['cat']), isTrue);
      expect(model.isSelected(['dog']), isTrue);
      expect(model.isSelected(['bird']), isFalse);
    });
  });
}
