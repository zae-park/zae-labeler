import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/edit_project_meta_use_case.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../mocks/mock_project_repository.dart';

void main() {
  group('ChangeLabelingModeUseCase', () {
    late MockProjectRepository repository;
    late EditProjectMetaUseCase useCase;

    setUp(() {
      repository = MockProjectRepository();
      useCase = EditProjectMetaUseCase(repository: repository);
    });

    test('changes labeling mode and clears labels', () async {
      final original = Project.empty().copyWith(id: 'p1', name: 'Test');
      await repository.saveProject(original);

      await useCase.changeLabelingMode('p1', LabelingMode.multiClassification);

      final updated = await repository.findById('p1');
      expect(updated?.mode, LabelingMode.multiClassification);
      expect(updated?.labels, isEmpty);
    });
  });
}
