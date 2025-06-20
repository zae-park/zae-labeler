import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/manage_data_info_use_case.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ManageDataInfoUseCase', () {
    late ManageDataInfoUseCase useCase;
    late MockProjectRepository repo;

    setUp(() {
      repo = MockProjectRepository();
      useCase = ManageDataInfoUseCase(repository: repo);
    });

    test('replaceAll replaces all dataInfos', () async {
      final project = Project.empty().copyWith(id: 'p1');
      await repo.saveProject(project);

      final newData = [DataInfo(fileName: 'file.csv')];
      await useCase.replaceAll('p1', newData);

      final result = await repo.findById('p1');
      expect(result?.dataInfos.length, 1);
    });

    test('add appends a new DataInfo', () async {
      final project = Project.empty().copyWith(id: 'p2');
      await repo.saveProject(project);

      await useCase.addData('p2', DataInfo(fileName: 'test.json'));
      final result = await repo.findById('p2');
      expect(result?.dataInfos.first.fileName, 'test.json');
    });

    test('removeById deletes specific DataInfo', () async {
      final data = DataInfo(fileName: 'sample.csv');
      final project = Project.empty().copyWith(id: 'p3', dataInfos: [data]);
      await repo.saveProject(project);

      await useCase.removeById('p3', data.id);
      final result = await repo.findById('p3');
      expect(result?.dataInfos.length, 0);
    });
  });
}
