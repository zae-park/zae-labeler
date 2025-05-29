import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/delete_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('DeleteProjectUseCase', () {
    late MockProjectRepository mockRepository;
    late DeleteProjectUseCase useCase;

    setUp(() {
      mockRepository = MockProjectRepository();
      useCase = DeleteProjectUseCase(repository: mockRepository);
    });

    test('deleteById delegates to repository.deleteById()', () async {
      await useCase.deleteById('p2');
      verify(mockRepository.deleteById('p2')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('deleteAll filters projectIds and calls saveAll()', () async {
      final all = [
        Project.empty().copyWith(id: 'p1'),
        Project.empty().copyWith(id: 'p2'),
        Project.empty().copyWith(id: 'p3'),
      ];
      when(mockRepository.fetchAllProjects()).thenAnswer((_) async => all);

      await useCase.deleteAll(['p2', 'p3']);

      final expected = [all[0]];
      verify(mockRepository.fetchAllProjects()).called(1);
      verify(mockRepository.saveAll(expected)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
