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

    test('creates project', () async {
      final invalidProject = Project.empty().copyWith(id: 'new-id', name: 'New Project');
      expect(() async => await useCase.call(invalidProject), throwsA(isA<ArgumentError>()));
      final newProject = Project.empty();
      newProject.updateName("New Project");
      newProject.updateClasses(["clas1s1", "class2"]);
      expect(newProject.name, 'New Project');
    });
  });
}
