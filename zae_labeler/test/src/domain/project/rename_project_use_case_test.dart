import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/rename_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('RenameProjectUseCase', () {
    late MockProjectRepository repository;
    late RenameProjectUseCase useCase;

    setUp(() {
      repository = MockProjectRepository();
      useCase = RenameProjectUseCase(repository: repository);
    });

    test('updates project name and saves it', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'Old');
      await repository.saveProject(project);

      await useCase.call('p1', 'NewName');

      final updated = await repository.findById('p1');
      expect(updated?.name, 'NewName');
    });
  });
}
