import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';
import '../../mocks/mock_project_repository.dart';

void main() {
  group('ProjectListViewModel', () {
    late ProjectListViewModel vm;
    late MockProjectRepository mockRepository;

    final sampleProject = Project(
      id: 'test1',
      name: 'Sample Project',
      mode: LabelingMode.singleClassification,
      classes: [],
    );

    setUp(() {
      mockRepository = MockProjectRepository();
      vm = ProjectListViewModel(repository: mockRepository);
    });

    test('saveProject adds new project', () async {
      await vm.saveProject(sampleProject);

      expect(vm.projects.length, 1);
      expect(vm.projects.first.name, 'Sample Project');
      expect(mockRepository.wasSaveAllCalled, true);
    });

    test('removeProject deletes a project', () async {
      await vm.saveProject(sampleProject);
      await vm.removeProject('test1');

      expect(vm.projects.any((p) => p.id == 'test1'), false);
      expect(mockRepository.wasSaveAllCalled, true);
    });

    test('updateProject modifies project data', () async {
      await vm.saveProject(sampleProject);

      final updated = sampleProject.copyWith(name: 'Updated Name');
      await vm.updateProject(updated);

      expect(vm.projects.first.name, 'Updated Name');
      expect(mockRepository.wasSaveAllCalled, true);
    });

    test('clearAllProjectsCache clears everything', () async {
      await vm.saveProject(sampleProject);
      await vm.clearAllProjectsCache();

      expect(vm.projects.isEmpty, true);
    });
  });
}
