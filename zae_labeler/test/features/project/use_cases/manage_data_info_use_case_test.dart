import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/project/use_cases/manage_data_info_use_case.dart';
import 'package:zae_labeler/src/core/models/data/data_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';

import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('ManageDataInfoUseCase', () {
    late ManageDataInfoUseCase useCase;
    late MockProjectRepository repo;

    setUp(() {
      repo = MockProjectRepository();
      useCase = ManageDataInfoUseCase(repository: repo);
    });

    test('addData appends a new DataInfo', () async {
      final project = Project.empty().copyWith(id: 'p1');
      await repo.saveProject(project);

      final added = await useCase.addData(
        projectId: 'p1',
        dataInfo: DataInfo(fileName: 'file.csv'),
      );

      expect(added!.dataInfos.length, 1);
      expect(added.dataInfos.first.fileName, 'file.csv');
    });

    test('removeData deletes DataInfo by index', () async {
      final data = DataInfo(fileName: 'sample.csv');
      final project = Project.empty().copyWith(id: 'p2', dataInfos: [data]);
      await repo.saveProject(project);

      final removed = await useCase.removeData(projectId: 'p2', dataIndex: 0);
      expect(removed!.dataInfos, isEmpty);
    });

    // test('removeData throws on invalid index', () async {
    //   final project = Project.empty().copyWith(id: 'p3');
    //   await repo.saveProject(project);

    //   expect(
    //     () => useCase.removeData(projectId: 'p3', dataIndex: 5),
    //     throwsException,
    //   );
    // });

    test('removeAll clears all DataInfos', () async {
      final data1 = DataInfo(fileName: 'data1.csv');
      final data2 = DataInfo(fileName: 'data2.csv');
      final project = Project.empty().copyWith(id: 'p4', dataInfos: [data1, data2]);
      await repo.saveProject(project);

      final cleared = await useCase.removeAll('p4');
      expect(cleared!.dataInfos, isEmpty);
    });
  });
}
