// 📁 test/view_models/cross_classification_labeling_view_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/view_models/sub_view_models/classification_labeling_view_model.dart';

import '../../../mocks/mock_storage_helper.dart';
import '../../../mocks/mock_path_provider.dart';

void main() {
  setUpAll(() {
    MockPathProvider.setup();
  });

  group('CrossClassificationLabelingViewModel', () {
    late CrossClassificationLabelingViewModel viewModel;

    setUp(() async {
      final project = Project(
        id: 'test-project',
        name: 'Test Project',
        mode: LabelingMode.crossClassification,
        dataPaths: ['A', 'B', 'C'].map((id) => DataPath(id: id, fileName: '$id.jpg')).toList(),
        classes: ['positive', 'negative'],
      );

      viewModel = CrossClassificationLabelingViewModel(project: project, storageHelper: MockStorageHelper());

      await viewModel.initialize();
    });

    test('totalPairCount is correct for 3 data items', () {
      expect(viewModel.totalPairCount, 3); // (A,B), (A,C), (B,C)
    });

    test('currentPair returns correct initial pair', () {
      final pair = viewModel.currentPair;
      expect(pair?.sourceId, 'A');
      expect(pair?.targetId, 'B');
      expect(pair?.relation, '');
    });

    test('moveNext and movePrevious navigate between pairs', () async {
      expect(viewModel.currentPair?.sourceId, 'A');
      expect(viewModel.currentPair?.targetId, 'B');

      await viewModel.moveNext();
      expect(viewModel.currentPair?.sourceId, 'A');
      expect(viewModel.currentPair?.targetId, 'C');

      await viewModel.moveNext();
      expect(viewModel.currentPair?.sourceId, 'B');
      expect(viewModel.currentPair?.targetId, 'C');

      await viewModel.movePrevious();
      expect(viewModel.currentPair?.sourceId, 'A');
      expect(viewModel.currentPair?.targetId, 'C');
    });

    test('updateLabel sets relation and isLabelSelected is correct', () async {
      await viewModel.updateLabel('positive');

      expect(viewModel.currentPair?.relation, 'positive');
      expect(viewModel.isLabelSelected('positive'), isTrue);
      expect(viewModel.isLabelSelected('negative'), isFalse);
    });

    test('toggleLabel behaves same as updateLabel', () async {
      viewModel.toggleLabel('negative');

      expect(viewModel.currentPair?.relation, 'negative');
      expect(viewModel.isLabelSelected('negative'), isTrue);
    });
  });
}
