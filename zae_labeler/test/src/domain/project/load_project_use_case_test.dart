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
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      final result = await useCase.loadAll();

      expect(result.length, 2);
      expect(result[0].name, 'Alpha');
      verify(mockHelper.loadProjectList()).called(1);
    });

    test('loadById returns correct project if exists', () async {
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      final result = await useCase.loadById('p2');

      expect(result, isNotNull);
      expect(result!.name, 'Beta');
    });

    test('loadById returns null if not found', () async {
      when(mockHelper.loadProjectList()).thenAnswer((_) async => mockProjects);

      final result = await useCase.loadById('not_exist');

      expect(result, isNull);
    });
  });
}
