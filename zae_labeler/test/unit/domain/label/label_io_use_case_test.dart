import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/label/label_io_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';

import '../../../mocks/repositories/mock_label_repository.dart';

void main() {
  group('LabelIOUseCase', () {
    late LabelIOUseCase useCase;
    late MockLabelRepository repo;

    setUp(() {
      repo = MockLabelRepository();
      useCase = LabelIOUseCase(repo);
    });

    test('export returns mock file path', () async {
      final project = Project.empty().copyWith(id: 'p1');
      final labels = [
        LabelModelFactory.createNew(LabelingMode.singleClassification, dataId: 'a'),
      ];

      final result = await useCase.exportLabels(project, labels);
      expect(result, contains('p1_labels.json'));
    });

    test('exportWithData returns mock file path with data', () async {
      final project = Project.empty().copyWith(id: 'p1');
      final labels = [
        LabelModelFactory.createNew(LabelingMode.multiClassification, dataId: 'b'),
      ];
      final dataInfos = [DataInfo(fileName: 'sample.csv')];

      final result = await useCase.exportLabelsWithData(project, labels, dataInfos);
      expect(result, contains('p1_full.json'));
    });
  });
}
