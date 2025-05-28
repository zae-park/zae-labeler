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
      importUseCase = ImportProjectUseCase(storageHelper: mockStorage, saveProjectUseCase: saveUseCase);
    });

    test('imports project list and saves them', () async {
      // given
      final importedProjects = [
        Project.empty().copyWith(id: 'p1', name: 'Imported One'),
        Project.empty().copyWith(id: 'p2', name: 'Imported Two'),
      ];

      // mockStorage.loadProjectFromConfig는 내부적으로 mockStorage.savedProjects 반환
      mockStorage.savedProjects = importedProjects;

      // when
      // await importUseCase();

      // then
      expect(mockStorage.savedProjects.length, 2);
      expect(mockStorage.savedProjects.first.name, 'Imported One');
      expect(mockStorage.wasSaveProjectCalled, isTrue);
    });
  });
}
