import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/domain/project/save_project_use_case.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockStorageHelper extends Mock implements StorageHelperInterface {}

void main() {
  test('SaveProjectUseCase adds new project if not exist', () async {
    final helper = MockStorageHelper();
    final useCase = SaveProjectUseCase(storageHelper: helper);

    final current = <Project>[];
    final newProject = Project.empty().copyWith(name: 'Test Project');

    await useCase(newProject, current);

    expect(current.length, 1);
    expect(current[0].name, 'Test Project');

    // ✅ 정확한 타입 지정
    verify(helper.saveProjectList(any<List<Project>>())).called(1);
  });
}
