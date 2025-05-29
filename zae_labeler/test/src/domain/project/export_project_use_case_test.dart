import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/export_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/repositories/project_repository.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  group('ExportProjectUseCase', () {
    late MockProjectRepository mockRepository;
    late ExportProjectUseCase useCase;

    setUp(() {
      mockRepository = MockProjectRepository();
      useCase = ExportProjectUseCase(repository: mockRepository);
    });

    test('calls repository.exportConfig and returns path', () async {
      final project = Project.empty().copyWith(id: 'p1', name: 'Test Project');
      const mockPath = '/tmp/test_project.json';

      when(mockRepository.exportConfig(project)).thenAnswer((_) async => mockPath);

      final result = await useCase.call(project);

      expect(result, mockPath);
      verify(mockRepository.exportConfig(project)).called(1);
    });
  });
}
