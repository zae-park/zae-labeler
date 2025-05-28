import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/delete_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockStorageHelper extends Mock implements StorageHelperInterface {}

void main() {
  group('DeleteProjectUseCase', () {
    late MockStorageHelper mockHelper;
    late DeleteProjectUseCase useCase;
    late List<Project> mockProjects;

    setUp(() {
      mockHelper = MockStorageHelper();
      useCase = DeleteProjectUseCase(storageHelper: mockHelper);
      mockProjects = [
        Project.empty().copyWith(id: 'p1', name: 'Alpha'),
        Project.empty().copyWith(id: 'p2', name: 'Beta'),
        Project.empty().copyWith(id: 'p3', name: 'Gamma'),
      ];
    });

    test('deleteById removes matching project and saves list', () async {
      await useCase.deleteById('p2', mockProjects);

      expect(mockProjects.length, 2);
      expect(mockProjects.any((p) => p.id == 'p2'), false);
      verify(mockHelper.saveProjectList(mockProjects)).called(1);
    });

    test('deleteById does nothing if project ID not found', () async {
      await useCase.deleteById('not_found', mockProjects);

      expect(mockProjects.length, 3);
      verify(mockHelper.saveProjectList(mockProjects)).called(1);
    });

    test('deleteAll saves given list directly', () async {
      final remaining = [mockProjects[0], mockProjects[2]];

      await useCase.deleteAll(remaining);

      verify(mockHelper.saveProjectList(remaining)).called(1);
    });
  });
}
