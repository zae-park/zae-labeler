import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_project_repository.dart';

void main() {
  group('SaveProjectUseCase (with repository)', () {
    late MockProjectRepository mockRepository;
    late SaveProjectUseCase useCase;

    setUp(() {
      mockRepository = MockProjectRepository();
      useCase = SaveProjectUseCase(repository: mockRepository);
    });

    test('saveOne validates and delegates to repository', () async {
      final project = Project.empty().copyWith(id: '123', name: 'Valid Project');

      await useCase.saveOne(project);

      verify(mockRepository.saveProject(project)).called(1);
    });

    test('saveAll delegates to repository.saveAll()', () async {
      final list = [
        Project.empty().copyWith(id: '1', name: 'Alpha'),
        Project.empty().copyWith(id: '2', name: 'Beta'),
      ];

      await useCase.saveAll(list);

      verify(mockRepository.saveAll(list)).called(1);
    });
  });
}
