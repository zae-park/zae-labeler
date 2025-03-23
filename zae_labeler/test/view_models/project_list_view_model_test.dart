import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import '../mocks/mock_storage_helper.dart';

void main() {
  group('ProjectListViewModel', () {
    late ProjectListViewModel vm;
    late MockStorageHelper mock;

    setUp(() {
      mock = MockStorageHelper();
      vm = ProjectListViewModel(storageHelper: mock);
    });

    test('saveProject adds new project', () async {
      final project = Project(id: 'id1', name: 'test', mode: LabelingMode.singleClassification, classes: []);
      await vm.saveProject(project);
      expect(vm.projects.length, 1);
      expect(vm.projects.first.name, 'test');
    });

    test('removeProject deletes a project', () async {
      final project = Project(id: 'id2', name: 'to delete', mode: LabelingMode.singleClassification, classes: []);
      await vm.saveProject(project);
      await vm.removeProject('id2');
      expect(vm.projects.any((p) => p.id == 'id2'), false);
    });

    test('updateProject modifies project data', () async {
      final project = Project(id: 'id3', name: 'old', mode: LabelingMode.singleClassification, classes: []);
      await vm.saveProject(project);
      final updated = project.copyWith(name: 'updated');
      await vm.updateProject(updated);
      expect(vm.projects.first.name, 'updated');
    });

    test('clearAllProjectsCache clears everything', () async {
      final project = Project(id: 'id4', name: 'will be cleared', mode: LabelingMode.singleClassification, classes: []);
      await vm.saveProject(project);
      await vm.clearAllProjectsCache();
      expect(vm.projects.isEmpty, true);
    });
  });
}
