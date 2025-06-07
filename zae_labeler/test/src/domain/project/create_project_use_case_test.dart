import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/create_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('CreateProjectUseCase', () {
    late MockProjectRepository repository;
    late CreateProjectUseCase useCase;

    setUp(() {
      repository = MockProjectRepository();
      useCase = CreateProjectUseCase(repository: repository);
    });

    test('creates a new project and saves it', () async {
      final newProject = Project.empty().copyWith(id: 'new-id', name: 'New Project');
      await useCase.call(newProject);

      final result = await repository.findById('new-id');
      expect(result?.name, 'New Project');
      expect(repository.wasSaveProjectCalled, true);
    });
  });
}
