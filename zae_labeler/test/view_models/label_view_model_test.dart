import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/view_models/label_view_model.dart';

void main() {
  group('LabelViewModel', () {
    late LabelViewModel labelVM;

    setUp(() {
      labelVM = LabelViewModel(
        projectId: 'proj-1',
        dataFilename: 'data-1.txt',
        dataPath: '/path/data-1.txt',
        mode: LabelingMode.singleClassification,
        labelModel: SingleClassificationLabelModel(label: 'init', labeledAt: DateTime.now()),
      );
    });

    test('initial label is correct', () {
      expect(labelVM.labelModel.label, equals('init'));
    });

    test('update label replaces label model', () {
      labelVM.updateLabel('new');
      expect(labelVM.labelModel.label, equals('new'));
    });

    test('isSelected returns true for current label', () {
      labelVM.updateLabel('target');
      expect(labelVM.isSelected('target'), isTrue);
      expect(labelVM.isSelected('other'), isFalse);
    });
  });
}
