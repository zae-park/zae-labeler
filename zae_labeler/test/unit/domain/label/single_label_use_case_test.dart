import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';
import '../../../mocks/use_cases/label/mock_single_label_use_case.dart';

void main() {
  group('MockSingleLabelUseCase', () {
    late MockSingleLabelUseCase useCase;
    const projectId = 'test_project';
    const dataId = 'data_001';
    const dataPath = '/mock/path/data_001.jpg';
    const mode = LabelingMode.singleClassification;

    setUp(() {
      useCase = MockSingleLabelUseCase(repository: MockLabelRepository());
    });

    test('loadLabel returns default if not exists', () async {
      final label = await useCase.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
      expect(label.dataId, dataId);
    });

    // test('saveLabel stores label correctly', () async {
    //   final label = LabelModelFactory.createNew(mode, dataId: dataId).copyWith(label: 'A');

    //   await useCase.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: label);

    //   final loaded = await useCase.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    //   expect(loaded.label, 'A');
    // });

    // test('loadOrCreateLabel returns existing label if exists', () async {
    //   final label = LabelModelFactory.createNew(mode, dataId: dataId)..label = 'B';
    //   await useCase.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: label);
    //   final result = await useCase.loadOrCreateLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    //   expect(result.label, 'B');
    // });

    // test('isLabeled returns true when label is present', () {
    //   final labeled = LabelModelFactory.createNew(mode, dataId: dataId)..label = 'C';
    //   expect(useCase.isLabeled(labeled), true);

    //   final empty = LabelModelFactory.createNew(mode, dataId: dataId);
    //   expect(useCase.isLabeled(empty), false);
    // });
  });
}
