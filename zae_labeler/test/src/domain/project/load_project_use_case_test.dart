import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/load_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/mock_project_repository.dart';

void main() {
  group('LoadProjectsUseCase', () {
    late MockProjectRepository mockRepository;
    late LoadProjectsUseCase useCase;

    final mockProjects = [
      Project.empty().copyWith(id: 'p1', name: 'Alpha'),
      Project.empty().copyWith(id: 'p2', name: 'Beta'),
    ];

    setUp(() {
      mockRepository = MockProjectRepository();
      useCase = LoadProjectsUseCase(repository: mockRepository);
    });

    test('loadAll returns all projects', () async {
      // arrange
      when(mockRepository.fetchAllProjects()).thenAnswer((_) async => mockProjects);

      // act
      final result = await useCase.loadAll();

      // assert
      expect(result, hasLength(2));
      expect(result[0].id, 'p1');
      expect(result[1].name, 'Beta');
      verify(mockRepository.fetchAllProjects()).called(1);
    });

    test('loadById returns correct project if exists', () async {
      // arrange
      when(mockRepository.findById('p2')).thenAnswer((_) async => mockProjects[1]);

      // act
      final result = await useCase.loadById('p2');

      // assert
      expect(result, isNotNull);
      expect(result!.id, 'p2');
      expect(result.name, 'Beta');
      verify(mockRepository.findById('p2')).called(1);
    });

    test('loadById returns null if not found', () async {
      // arrange
      when(mockRepository.findById('not_exist')).thenAnswer((_) async => null);

      // act
      final result = await useCase.loadById('not_exist');

      // assert
      expect(result, isNull);
      verify(mockRepository.findById('not_exist')).called(1);
    });
  });
}
