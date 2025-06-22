import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';
import '../../../mocks/use_cases/label/mock_batch_label_use_case.dart';

void main() {
  group('MockBatchLabelUseCase', () {
    late MockBatchLabelUseCase useCase;
    const projectId = 'test_project';

    final label1 = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: '1');
    final label2 = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: '2');

    setUp(() {
      useCase = MockBatchLabelUseCase(repository: MockLabelRepository());
    });

    test('saveAllLabels stores the labels internally', () async {
      await useCase.saveAllLabels(projectId, [label1, label2]);

      expect(useCase.savedLabels.length, 2);
      expect(useCase.savedLabels, containsAll([label1, label2]));
    });

    test('loadAllLabels returns previously saved labels', () async {
      await useCase.saveAllLabels(projectId, [label1]);
      final labels = await useCase.loadAllLabels(projectId);

      expect(labels.length, 1);
      expect(labels.first.dataId, '1');
    });

    test('loadLabelMap returns the mocked label map', () async {
      useCase.mockLabelMap = {'2': label2};
      final map = await useCase.loadLabelMap(projectId);

      expect(map.containsKey('2'), true);
      expect(map['2'], label2);
    });

    test('deleteAllLabels clears stored labels and updates flags', () async {
      await useCase.saveAllLabels(projectId, [label1]);
      await useCase.deleteAllLabels(projectId);

      expect(useCase.savedLabels, isEmpty);
      expect(useCase.savedLabelMap, isEmpty);
      expect(useCase.wasDeleteAllCalled, true);
    });
  });
}
