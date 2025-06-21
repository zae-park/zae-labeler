import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/label/batch_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';

void main() {
  group('BatchLabelUseCase', () {
    late BatchLabelUseCase useCase;
    late MockLabelRepository repo;

    setUp(() {
      repo = MockLabelRepository();
      useCase = BatchLabelUseCase(repo);
    });

    test('saveAll stores all labels', () async {
      const projectId = 'p1';
      final labels = [
        LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'a'),
        LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'b'),
      ];

      await useCase.saveAllLabels(projectId, labels);
      final stored = await repo.loadAllLabels(projectId);

      expect(stored.length, 2);
      expect(stored.map((e) => e.dataId), containsAll(['a', 'b']));
    });

    test('deleteAll clears labels', () async {
      const projectId = 'p2';
      final labels = [
        LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'x'),
        LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'y'),
      ];
      await repo.saveAllLabels(projectId, labels);

      await useCase.deleteAllLabels(projectId);
      final stored = await repo.loadAllLabels(projectId);
      expect(stored, isEmpty);
    });
  });
}
