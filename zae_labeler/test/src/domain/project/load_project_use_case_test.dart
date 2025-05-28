import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/load_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockStorageHelper extends Mock implements StorageHelperInterface {}

void main() {
  group('LoadProjectsUseCase', () {
    late MockStorageHelper mockHelper;
    late LoadProjectsUseCase useCase;

    final mockProjects = [
      Project.empty().copyWith(id: 'p1', name: 'Alpha'),
      Project.empty().copyWith(id: 'p2', name: 'Beta'),
    ];

    setUp(() {
      mockHelper = MockStorageHelper();
      useCase = LoadProjectsUseCase(storageHelper: mockHelper);
    });

    test('loadAll returns all projects', () async {
      // arrange
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      // act
      final result = await useCase.loadAll();

      // assert
      expect(result, hasLength(2));
      expect(result[0].id, 'p1');
      expect(result[1].name, 'Beta');
      verify(mockHelper.loadProjectList()).called(1);
    });

    test('loadById returns correct project if exists', () async {
      // arrange
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      // act
      final result = await useCase.loadById('p2');

      // assert
      expect(result, isNotNull);
      expect(result!.id, 'p2');
      expect(result.name, 'Beta');
    });

    test('loadById returns null if not found', () async {
      // arrange
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      // act
      final result = await useCase.loadById('not_exist');

      // assert
      expect(result, isNull);
    });
  });
}
