import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/label/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/view_models/managers/label_input_mapper.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_label_view_model.dart';

import '../../../mocks/use_cases/label/mock_label_use_cases.dart';

void main() {
  group('ClassificationLabelViewModel', () {
    const projectId = 'test_project';
    const dataId = 'data_001';
    const dataPath = '/mock/path/data_001.jpg';
    const dataFilename = 'data_001.jpg';
    const mode = LabelingMode.singleClassification;

    late ClassificationLabelViewModel viewModel;

    setUp(() {
      viewModel = ClassificationLabelViewModel(
        projectId: projectId,
        dataId: dataId,
        dataFilename: dataFilename,
        dataPath: dataPath,
        mode: mode,
        labelModel: SingleClassificationLabelModel(dataId: dataId, label: null, labeledAt: DateTime.now()),
        labelUseCases: MockLabelUseCases(),
        labelInputMapper: SingleClassificationInputMapper(),
      );
    });

    test('loadLabel fetches and assigns labelModel', () async {
      await viewModel.loadLabel();
      expect(viewModel.labelModel.dataId, equals(dataId));
    });

    test('saveLabel does not throw and stores label', () async {
      await viewModel.saveLabel();
    });

    test('updateLabel assigns and saves new label', () async {
      final newLabel = SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: DateTime.now(), label: 'B');

      await viewModel.updateLabel(newLabel);
      expect(viewModel.labelModel.label, equals('B'));
    });

    test('updateLabelFromInput maps and updates label', () async {
      await viewModel.updateLabelFromInput('X');
      expect(viewModel.labelModel.label, equals('X'));
    });

    test('toggleLabel updates label via updateLabelFromInput', () async {
      await viewModel.toggleLabel('Y');
      expect(viewModel.labelModel.label, equals('Y'));
    });

    test('isLabelSelected returns true if label matches', () async {
      await viewModel.updateLabelFromInput('A');
      expect(viewModel.isLabelSelected('A'), isTrue);
      expect(viewModel.isLabelSelected('B'), isFalse);
    });

    test('multi-label toggles on/off correctly', () async {
      final multiVM = ClassificationLabelViewModel(
        projectId: projectId,
        dataId: dataId,
        dataFilename: dataFilename,
        dataPath: dataPath,
        mode: LabelingMode.multiClassification,
        labelModel: MultiClassificationLabelModel(dataId: dataId, label: {'X'}, labeledAt: DateTime.now()),
        labelUseCases: MockLabelUseCases(),
        labelInputMapper: MultiClassificationInputMapper(),
      );

      await multiVM.updateLabelFromInput('X'); // toggle off
      expect((multiVM.labelModel as MultiClassificationLabelModel).label, isEmpty);

      await multiVM.updateLabelFromInput('Y'); // toggle on
      expect((multiVM.labelModel as MultiClassificationLabelModel).label, contains('Y'));
    });
  });
}
