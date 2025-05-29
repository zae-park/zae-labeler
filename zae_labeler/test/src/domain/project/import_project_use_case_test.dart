import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/import_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_project_repository.dart';

void main() {
  group('ImportProjectUseCase', () {
    late MockProjectRepository mockRepository;
    late ImportProjectUseCase importUseCase;

    setUp(() {
      mockRepository = MockProjectRepository();
      importUseCase = ImportProjectUseCase(repository: mockRepository);
    });

    test('imports project from repository and saves it', () async {
      // given
      final importedProjects = [
        Project.empty().copyWith(id: 'p1', name: 'Imported One'),
        Project.empty().copyWith(id: 'p2', name: 'Imported Two'),
      ];
      when(mockRepository.importFromExternal()).thenAnswer((_) async => importedProjects);

      // when
      await importUseCase.call();

      // then
      verify(mockRepository.importFromExternal()).called(1);
      verify(mockRepository.saveProject(importedProjects.first)).called(1);
    });

    test('throws StateError if no projects are imported', () async {
      when(mockRepository.importFromExternal()).thenAnswer((_) async => []);

      // when/then
      expect(() async => await importUseCase.call(), throwsA(isA<StateError>()));
    });
  });
}
