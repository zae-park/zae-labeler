import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/manage_project_io_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ManageProjectIOUseCase', () {
    late ManageProjectIOUseCase useCase;
    late MockProjectRepository repo;

    setUp(() {
      repo = MockProjectRepository();
      useCase = ManageProjectIOUseCase(repository: repo);
    });

    test('importProject returns imported projects', () async {
      final imported = await useCase.importProject();
      expect(imported, isA<List<Project>>());
    });

    test('exportProject returns path', () async {
      final project = Project.empty().copyWith(id: 'p1');
      final result = await useCase.exportProject(project);
      expect(result, contains('p1'));
    });
  });
}
