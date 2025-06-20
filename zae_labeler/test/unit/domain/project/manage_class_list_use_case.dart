import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/manage_class_list_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ManageClassListUseCase', () {
    late ManageClassListUseCase useCase;
    late MockProjectRepository repo;

    setUp(() {
      repo = MockProjectRepository();
      useCase = ManageClassListUseCase(repository: repo);
    });

    test('updateClasses modifies class list', () async {
      final project = Project.empty().copyWith(id: 'p1');
      await repo.saveProject(project);

      await useCase.updateClasses('p1', ['A', 'B', 'C']);
      final updated = await repo.findById('p1');
      expect(updated?.classList, ['A', 'B', 'C']);
    });
  });
}
