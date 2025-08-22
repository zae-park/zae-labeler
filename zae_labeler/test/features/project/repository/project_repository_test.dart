// test/unit/repositories/project_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import '../../../mocks/repositories/mock_project_repository.dart';

void main() {
  group('MockProjectRepository', () {
    late MockProjectRepository repository;
    final testProject = Project.empty().copyWith(id: 'p1', name: 'Test Project');

    setUp(() {
      repository = MockProjectRepository();
    });

    test('saveProject adds project and fetchAllProjects returns it', () async {
      await repository.saveProject(testProject);
      final result = await repository.fetchAllProjects();
      expect(result.length, 1);
      expect(result.first.name, 'Test Project');
    });

    test('findById returns correct project', () async {
      await repository.saveProject(testProject);
      final found = await repository.findById('p1');
      expect(found?.name, 'Test Project');
    });

    test('deleteById removes the project', () async {
      await repository.saveProject(testProject);
      await repository.deleteById('p1');
      final result = await repository.fetchAllProjects();
      expect(result.isEmpty, true);
    });

    test('deleteAll clears all projects', () async {
      await repository.saveProject(testProject);
      await repository.saveProject(testProject.copyWith(id: 'p2'));
      await repository.deleteAll();
      expect(await repository.fetchAllProjects(), isEmpty);
    });

    test('updateProjectMode modifies mode', () async {
      await repository.saveProject(testProject);
      final updated = await repository.updateProjectMode('p1', LabelingMode.multiClassification);
      expect(updated?.mode, LabelingMode.multiClassification);
    });

    test('updateProjectClasses modifies classes', () async {
      await repository.saveProject(testProject);
      await repository.updateProjectClasses('p1', ['cat', 'dog']);
      final result = await repository.findById('p1');
      expect(result?.classes, containsAll(['cat', 'dog']));
    });

    test('updateProjectName changes the name', () async {
      await repository.saveProject(testProject);
      final updated = await repository.updateProjectName('p1', 'New Name');
      expect(updated?.name, 'New Name');
    });

    test('updateDataInfos replaces data list', () async {
      await repository.saveProject(testProject);
      final dataInfos = [const DataInfo(id: 'd1', fileName: 'img.png', filePath: '/path/img.png')];
      await repository.updateDataInfos('p1', dataInfos);
      final result = await repository.findById('p1');
      expect(result?.dataInfos.length, 1);
    });

    test('addDataInfo adds one data item', () async {
      await repository.saveProject(testProject);
      const newData = DataInfo(id: 'd2', fileName: 'img2.png', filePath: '/path/img2.png');
      await repository.addDataInfo('p1', newData);
      final result = await repository.findById('p1');
      expect(result?.dataInfos.map((d) => d.id), contains('d2'));
    });

    test('removeDataInfoById deletes correct data', () async {
      final dataInfos = [
        const DataInfo(id: 'd1', fileName: 'img1.png', filePath: '/path/1'),
        const DataInfo(id: 'd2', fileName: 'img2.png', filePath: '/path/2'),
      ];
      await repository.saveProject(testProject.copyWith(dataInfos: dataInfos));
      await repository.removeDataInfoById('p1', 'd1');
      final result = await repository.findById('p1');
      expect(result?.dataInfos.length, 1);
      expect(result?.dataInfos.first.id, 'd2');
    });

    test('exportConfig returns mocked path', () async {
      final path = await repository.exportConfig(testProject);
      expect(path, 'mock_config_path.json');
    });
  });
}
