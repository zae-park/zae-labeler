import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/import_project_use_case.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../../../mocks/mock_storage_helper.dart';

void main() {
  group('ImportProjectUseCase', () {
    late MockStorageHelper mockStorage;
    late SaveProjectUseCase saveUseCase;
    late ImportProjectUseCase importUseCase;

    setUp(() {
      mockStorage = MockStorageHelper();
      saveUseCase = SaveProjectUseCase(storageHelper: mockStorage);
      importUseCase = ImportProjectUseCase(
        storageHelper: mockStorage,
        saveProjectUseCase: saveUseCase,
      );
    });

    test('imports a single project and saves it', () async {
      // given
      final importedProject = Project.empty().copyWith(id: 'p1', name: 'Imported One');

      // set mock return value (단일 프로젝트 설정)
      mockStorage.mockImportedProject = importedProject;

      // when
      await importUseCase.call();

      // then
      expect(mockStorage.savedProjects.length, 1);
      expect(mockStorage.savedProjects.first.name, 'Imported One');
      expect(mockStorage.wasSaveProjectCalled, isTrue);
    });
  });
}
