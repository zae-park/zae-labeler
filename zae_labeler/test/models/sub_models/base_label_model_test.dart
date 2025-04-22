import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/base_label_model.dart';

class DummyLabelModel extends LabelModel<String> {
  DummyLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  DummyLabelModel updateLabel(String labelData) {
    return DummyLabelModel(label: labelData, labeledAt: DateTime.now());
  }

  bool isSelected(String labelData) => label == labelData;

  @override
  Map<String, dynamic> toJson() {
    throw UnimplementedError();
  }

  @override
  bool get isLabeled => throw UnimplementedError();
}

void main() {
  group('BaseLabelModel', () {
    test('updateLabel returns new instance with updated label', () {
      final model = DummyLabelModel(label: 'a', labeledAt: DateTime(2024, 1, 1));
      final updated = model.updateLabel('b');

      expect(updated.label, equals('b'));
      expect(updated.label, isNot(equals(model.label)));
    });

    test('isSelected returns true only for matching label', () {
      final model = DummyLabelModel(label: 'x', labeledAt: DateTime(2024, 1, 1));
      expect(model.isSelected('x'), isTrue);
      expect(model.isSelected('y'), isFalse);
    });
  });
}
