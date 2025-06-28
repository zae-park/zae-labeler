import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/use_cases/project/edit_project_meta_use_case.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';

import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('EditProjectMetaUseCase', () {
    late EditProjectMetaUseCase useCase;
    late MockProjectRepository repo;

    setUp(() {
      repo = MockProjectRepository();
      useCase = EditProjectMetaUseCase(repository: repo);
    });

    test('rename updates the project name', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'Old Name');
      await repo.saveProject(project);

      final updated = await useCase.rename('p1', 'New Name');

      expect(updated?.name, 'New Name');
      expect(repo.wasSaveCalled, true);
    });

    test('updateMode changes the labeling mode', () async {
      final project = Project.empty().copyWith(id: 'p2');
      await repo.saveProject(project);

      final updated = await useCase.changeLabelingMode('p2', LabelingMode.multiClassification);
      expect(updated?.mode, LabelingMode.multiClassification);
    });
  });
}
