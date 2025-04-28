// 📁 test/view_models/cross_classification_labeling_view_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/view_models/sub_view_models/classification_labeling_view_model.dart';

import '../../mocks/mock_storage_helper.dart';
import '../../mocks/mock_path_provider.dart';

void main() {
  setUpAll(() {
    MockPathProvider.setup();
  });

  group('CrossClassificationLabelingViewModel', () {
    late CrossClassificationLabelingViewModel viewModel;

    setUp(() {
      final project = Project(
        id: 'test-project',
        name: 'Test Project',
        mode: LabelingMode.crossClassification,
        dataPaths: [],
        classes: ['positive', 'negative'],
      );

      viewModel = CrossClassificationLabelingViewModel(
        project: project,
        storageHelper: MockStorageHelper(),
      );
    });

    test('initializeCrossPairs creates correct number of pairs', () async {
      final selectedIds = ['A', 'B', 'C'];
      await viewModel.initializeCrossPairs(selectedIds);

      expect(viewModel.totalPairCount, 3); // (A,B), (A,C), (B,C)
    });

    test('currentPair returns correct source and target', () async {
      final selectedIds = ['X', 'Y', 'Z'];
      await viewModel.initializeCrossPairs(selectedIds);

      final pair = viewModel.currentPair;
      expect(pair?.sourceId, 'X');
      expect(pair?.targetId, 'Y');
      expect(pair?.relation, '');
    });

    test('moveNext and movePrevious navigate correctly', () async {
      final selectedIds = ['P', 'Q', 'R'];
      await viewModel.initializeCrossPairs(selectedIds);

      expect(viewModel.currentPair?.sourceId, 'P');
      expect(viewModel.currentPair?.targetId, 'Q');

      await viewModel.moveNext();
      expect(viewModel.currentPair?.sourceId, 'P');
      expect(viewModel.currentPair?.targetId, 'R');

      await viewModel.moveNext();
      expect(viewModel.currentPair?.sourceId, 'Q');
      expect(viewModel.currentPair?.targetId, 'R');

      await viewModel.movePrevious();
      expect(viewModel.currentPair?.sourceId, 'P');
      expect(viewModel.currentPair?.targetId, 'R');
    });

    test('updateLabel sets relation correctly', () async {
      final selectedIds = ['1', '2', '3'];
      await viewModel.initializeCrossPairs(selectedIds);

      await viewModel.updateLabel('positive');

      expect(viewModel.currentPair?.relation, 'positive');
      expect(viewModel.isLabelSelected('positive'), isTrue);
      expect(viewModel.isLabelSelected('negative'), isFalse);
    });

    test('toggleLabel updates relation', () async {
      final selectedIds = ['dog', 'cat'];
      await viewModel.initializeCrossPairs(selectedIds);

      viewModel.toggleLabel('negative');

      expect(viewModel.currentPair?.relation, 'negative');
      expect(viewModel.isLabelSelected('negative'), isTrue);
    });
  });
}
