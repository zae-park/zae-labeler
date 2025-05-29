import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/update_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('UpdateProjectUseCase (using ProjectRepository)', () {
    late MockProjectRepository mockRepository;
    late UpdateProjectUseCase useCase;

    setUp(() {
      mockRepository = MockProjectRepository();
      useCase = UpdateProjectUseCase(repository: mockRepository);
    });

    test('updates a valid project', () async {
      final project = Project.empty().copyWith(id: 'p001', name: 'Updated Project');

      await useCase.call(project);

      verify(mockRepository.saveProject(project)).called(1);
    });

    test('throws ArgumentError if ID is empty', () async {
      final invalid = Project.empty().copyWith(id: '');

      expect(() => useCase.call(invalid), throwsArgumentError);
    });
  });
}
