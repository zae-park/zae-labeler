import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/domain/project/update_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_storage_helper.dart';

void main() {
  group('UpdateProjectUseCase', () {
    late MockStorageHelper mockStorage;
    late SaveProjectUseCase saveUseCase;
    late UpdateProjectUseCase updateUseCase;

    setUp(() {
      mockStorage = MockStorageHelper();
      saveUseCase = SaveProjectUseCase(storageHelper: mockStorage);
      updateUseCase = UpdateProjectUseCase(saveProjectUseCase: saveUseCase);
    });

    test('updates a project with valid ID', () async {
      final original = Project.empty().copyWith(id: 'p001', name: 'Original');
      final updated = original.copyWith(name: 'Updated');

      // 기존 리스트에 프로젝트 존재
      mockStorage.savedProjects = [original];

      await updateUseCase.call(updated);

      expect(mockStorage.savedProjects.length, 1);
      expect(mockStorage.savedProjects.first.id, equals('p001'));
      expect(mockStorage.savedProjects.first.name, equals('Updated'));
    });

    test('throws if project ID is empty', () async {
      final invalidProject = Project.empty().copyWith(id: '');

      expect(() => updateUseCase.call(invalidProject), throwsArgumentError);
    });
  });
}
