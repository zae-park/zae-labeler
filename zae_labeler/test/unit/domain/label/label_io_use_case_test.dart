import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';
import '../../../mocks/use_cases/label/mock_io_label_use_case.dart';

void main() {
  group('MockLabelIOUseCase', () {
    late MockLabelIOUseCase useCase;
    late Project testProject;
    late LabelModel label1;
    late LabelModel label2;

    setUp(() {
      useCase = MockLabelIOUseCase(repository: MockLabelRepository());
      testProject = Project(id: 'p1', name: 'Project 1', mode: LabelingMode.singleClassification, classes: [], dataInfos: []);
      label1 = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: '1');
      label2 = LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: '2');
    });

    test('exportLabels stores project and labels internally and returns export path', () async {
      final path = await useCase.exportLabels(testProject, [label1, label2]);

      expect(path, equals(useCase.exportPath));
      expect(useCase.lastExportedProject, equals(testProject));
      expect(useCase.lastExportedLabels, containsAll([label1, label2]));
    });

    test('exportLabelsWithData returns export path', () async {
      final data = [DataInfo(fileName: 'file1.csv')];
      final path = await useCase.exportLabelsWithData(testProject, [label1], data);

      expect(path, equals(useCase.exportPath));
    });

    test('importLabels returns mock imported labels', () async {
      useCase.importedLabels = [label1, label2];
      final imported = await useCase.importLabels();

      expect(imported, containsAll([label1, label2]));
    });
  });
}
