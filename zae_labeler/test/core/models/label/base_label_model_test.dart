import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/classification_label_model.dart';

/// Tests common behaviour inherited from [LabelModel].
///
/// Since [LabelModel] is abstract, we instantiate a concrete
/// [SingleClassificationLabelModel] to verify that computed getters
/// like `labelData` and `formattedLabeledAt` behave as documented.
void main() {
  test('labelData and formattedLabeledAt provide convenience accessors', () {
    final timestamp = DateTime.parse('2024-05-01T00:00:00Z');
    final model = SingleClassificationLabelModel(dataId: 'data123', dataPath: '/tmp/file.txt', label: 'cat', labeledAt: timestamp);
    // labelData should alias the underlying label
    expect(model.labelData, equals('cat'));
    // formattedLabeledAt should be ISO‑8601 representation of the time
    expect(model.formattedLabeledAt, equals(timestamp.toIso8601String()));
    // dataId and dataPath should remain unchanged
    expect(model.dataId, equals('data123'));
    expect(model.dataPath, equals('/tmp/file.txt'));
  });
}
