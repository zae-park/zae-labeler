import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';

import '../../mocks/repositories/mock_label_repository.dart';

void main() {
  group('MockLabelRepository', () {
    late MockLabelRepository repository;
    const projectId = 'test-project';
    const dataId = 'data-001';
    const dataPath = '/mock/path/data.csv';

    final project = Project.empty().copyWith(id: projectId);
    final label = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: dataId);

    setUp(() {
      repository = MockLabelRepository();
    });

    test('save and load single label', () async {
      await repository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: label);
      final loaded = await repository.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: LabelingMode.singleClassification);

      expect(loaded.dataId, equals(dataId));
    });

    test('loadOrCreateLabel returns default when not found', () async {
      final created =
          await repository.loadOrCreateLabel(projectId: projectId, dataId: 'non-existent', dataPath: '/unused', mode: LabelingMode.singleClassification);

      expect(created.dataId, equals('non-existent'));
    });

    test('saveAllLabels and loadAllLabels', () async {
      final label2 = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'data-002');
      await repository.saveAllLabels(projectId, [label, label2]);

      final all = await repository.loadAllLabels(projectId);
      expect(all.length, 2);
      expect(all.map((e) => e.dataId).toSet(), containsAll(['data-001', 'data-002']));
    });

    test('deleteAllLabels removes labels', () async {
      await repository.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: label);
      await repository.deleteAllLabels(projectId);

      final loaded = await repository.loadAllLabels(projectId);
      expect(loaded.isEmpty, true);
    });

    test('export and import paths return mock paths', () async {
      final path = await repository.exportLabels(project, [label]);
      final pathWithData = await repository.exportLabelsWithData(project, [label], []);

      expect(path, contains(project.id));
      expect(pathWithData, contains('_with_data'));
    });

    test('validation and labeling checks return expected values', () {
      expect(repository.isValid(project, label), isTrue);
      expect(repository.getStatus(project, label), LabelStatus.complete);
      expect(repository.getStatus(project, null), LabelStatus.incomplete);
      expect(repository.isLabeled(label), label.isLabeled);
    });
  });
}
