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

    test('addClass adds a class to project if not duplicate', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A']);
      await repo.saveProject(project);

      final updated = await useCase.addClass('p1', 'B');
      expect(updated.classes, equals(['A', 'B']));
    });

    test('addClass does not add duplicate class', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A']);
      await repo.saveProject(project);

      final updated = await useCase.addClass('p1', 'A');
      expect(updated.classes, equals(['A']));
    });

    test('removeClass removes class at valid index', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A', 'B', 'C']);
      await repo.saveProject(project);

      final updated = await useCase.removeClass('p1', 1);
      expect(updated.classes, equals(['A', 'C']));
    });

    test('removeClass does nothing on invalid index', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A']);
      await repo.saveProject(project);

      final updated = await useCase.removeClass('p1', 3);
      expect(updated.classes, equals(['A']));
    });

    test('editClass updates class at index', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A', 'B']);
      await repo.saveProject(project);

      final updated = await useCase.editClass('p1', 1, 'Z');
      expect(updated.classes, equals(['A', 'Z']));
    });

    test('editClass does nothing on invalid index', () async {
      final project = Project.empty().copyWith(id: 'p1', classes: ['A']);
      await repo.saveProject(project);

      final updated = await useCase.editClass('p1', 2, 'Z');
      expect(updated.classes, equals(['A']));
    });
  });
}
