import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_storage_helper.dart';

void main() {
  group('SaveProjectUseCase (with stub helper)', () {
    late MockStorageHelper mockHelper;
    late SaveProjectUseCase useCase;

    setUp(() {
      mockHelper = MockStorageHelper();
      useCase = SaveProjectUseCase(storageHelper: mockHelper);
    });

    test('saveOne adds new project and saves updated list', () async {
      final newProject = Project.empty().copyWith(id: '123', name: 'New Project');

      // 🔹 savedProjects 초기값은 비어 있음
      mockHelper.savedProjects = [];

      await useCase.saveOne(newProject);

      expect(mockHelper.savedProjects.length, 1);
      expect(mockHelper.savedProjects.first.id, '123');
      expect(mockHelper.savedProjects.first.name, 'New Project');
      expect(mockHelper.wasSaveProjectCalled, isTrue);
    });

    test('saveOne updates existing project in list', () async {
      final old = Project.empty().copyWith(id: '123', name: 'Old');
      final updated = Project.empty().copyWith(id: '123', name: 'Updated');

      mockHelper.savedProjects = [old];

      await useCase.saveOne(updated);

      expect(mockHelper.savedProjects.length, 1);
      expect(mockHelper.savedProjects.first.id, '123');
      expect(mockHelper.savedProjects.first.name, 'Updated');
      expect(mockHelper.wasSaveProjectCalled, isTrue);
    });

    test('saveAll directly saves full list', () async {
      final list = [
        Project.empty().copyWith(id: '1', name: 'A'),
        Project.empty().copyWith(id: '2', name: 'B'),
      ];

      await useCase.saveAll(list);

      expect(mockHelper.savedProjects.length, 2);
      expect(mockHelper.savedProjects[1].name, 'B');
      expect(mockHelper.wasSaveProjectCalled, isTrue);
    });
  });
}
