import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/label/single_label_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';

void main() {
  group('SingleLabelUseCase', () {
    late SingleLabelUseCase useCase;
    late MockLabelRepository repo;

    setUp(() {
      repo = MockLabelRepository();
      useCase = SingleLabelUseCase(repo);
    });

    test('save stores a single label', () async {
      const projectId = 'proj1';
      const dataId = 'd1';
      final label = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: dataId);

      await useCase.saveLabel(projectId: projectId, dataId: dataId, dataPath: 'some/path', labelModel: label);
      final result = await repo.loadLabel(projectId: projectId, dataId: dataId, dataPath: 'some/path', mode: LabelingMode.singleClassification);

      expect(result, isNotNull);
      expect(result.dataId, equals(dataId));
    });

    test('load returns saved label', () async {
      const projectId = 'proj1';
      const dataId = 'd2';
      final label = LabelModelFactory.createNew(LabelingMode.multiClassification, dataId: dataId);
      await repo.saveLabel(projectId: projectId, dataId: dataId, dataPath: 'abc', labelModel: label);

      final result = await useCase.loadLabel(projectId: projectId, dataId: dataId, dataPath: 'abc', mode: LabelingMode.multiClassification);

      expect(result.dataId, equals(dataId));
    });

    test('loadOrCreate returns new label if not exists', () async {
      final result = await useCase.loadOrCreateLabel(projectId: 'proj1', dataId: 'new1', dataPath: 'none', mode: LabelingMode.singleClassification);

      expect(result.dataId, 'new1');
    });
  });
}
