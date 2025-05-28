import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockStorageHelper extends Mock implements StorageHelperInterface {}

void main() {
  group('SaveProjectUseCase', () {
    late MockStorageHelper mockHelper;
    late SaveProjectUseCase useCase;

    setUp(() {
      mockHelper = MockStorageHelper();
      useCase = SaveProjectUseCase(storageHelper: mockHelper);
    });

    test('saveOne adds new project and saves list', () async {
      final current = <Project>[];
      final newProject = Project.empty().copyWith(id: '123', name: 'New Project');

      await useCase.saveOne(newProject, current);

      expect(current.length, 1);
      expect(current[0].id, '123');
      verify(mockHelper.saveProjectList(current)).called(1);
    });

    test('saveOne updates existing project and saves list', () async {
      final current = [Project.empty().copyWith(id: '123', name: 'Old')];
      final updated = Project.empty().copyWith(id: '123', name: 'Updated');

      await useCase.saveOne(updated, current);

      expect(current.length, 1);
      expect(current[0].name, 'Updated');
      verify(mockHelper.saveProjectList(current)).called(1);
    });

    test('saveAll calls saveProjectList with full list', () async {
      final list = [Project.empty().copyWith(id: '1', name: 'A'), Project.empty().copyWith(id: '2', name: 'B')];

      await useCase.saveAll(list);

      verify(mockHelper.saveProjectList(list)).called(1);
    });
  });
}
