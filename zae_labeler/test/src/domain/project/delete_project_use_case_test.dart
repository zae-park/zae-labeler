import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/delete_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('DeleteProjectUseCase', () {
    late MockProjectRepository repository;
    late DeleteProjectUseCase useCase;

    setUp(() {
      repository = MockProjectRepository();
      useCase = DeleteProjectUseCase(repository: repository);
    });

    test('deleteById removes project from list', () async {
      final project = Project.empty().copyWith(id: 'p1');
      await repository.saveProject(project);

      await useCase.deleteById('p1');
      final result = await repository.findById('p1');

      expect(result, isNull);
      expect(repository.wasDeleteCalled, true);
    });

    test('deleteAll removes only specified projects', () async {
      await repository.saveProject(Project.empty().copyWith(id: 'p1'));
      await repository.saveProject(Project.empty().copyWith(id: 'p2'));
      await repository.saveProject(Project.empty().copyWith(id: 'p3'));

      await useCase.deleteAll(['p2', 'p3']);
      final remaining = await repository.fetchAllProjects();

      expect(remaining.map((e) => e.id), contains('p1'));
      expect(remaining.map((e) => e.id), isNot(contains('p2')));
      expect(remaining.map((e) => e.id), isNot(contains('p3')));
    });
  });
}
