import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../mocks/repositories/mock_project_repository.dart';
import '../../mocks/use_cases/project/mock_project_use_cases.dart';

void main() {
  group('ProjectListViewModel', () {
    late MockProjectRepository repo;
    late MockProjectUseCases useCases;
    late ProjectListViewModel viewModel;

    setUp(() {
      repo = MockProjectRepository();
      useCases = MockProjectUseCases();
      viewModel = ProjectListViewModel(projectUseCases: useCases);
    });

    test('loadProjects populates projectVMList', () async {
      final project1 = Project.empty().copyWith(id: 'p1', name: 'Test1');
      final project2 = Project.empty().copyWith(id: 'p2', name: 'Test2');
      await repo.saveAll([project1, project2]);

      await viewModel.loadProjects();
      expect(viewModel.projectVMList.length, 0);
      expect(viewModel.projectVMList.any((vm) => vm.project.id == 'p1'), isTrue);
      expect(viewModel.projectVMList.any((vm) => vm.project.id == 'p2'), isTrue);
    });

    test('upsertProject adds new project', () async {
      final project = Project.empty().copyWith(id: 'new', name: 'New Project');
      await viewModel.upsertProject(project);

      expect(viewModel.projectVMList.length, 1);
      expect(viewModel.getVMById('new')?.project.name, 'New Project');
    });

    test('upsertProject updates existing project', () async {
      final original = Project.empty().copyWith(id: 'dup', name: 'Original');
      await viewModel.upsertProject(original);

      final updated = original.copyWith(name: 'Updated');
      await viewModel.upsertProject(updated);

      expect(viewModel.projectVMList.length, 1);
      expect(viewModel.getVMById('dup')?.project.name, 'Updated');
    });

    test('removeProject deletes project from list', () async {
      final project = Project.empty().copyWith(id: 'remove');
      await viewModel.upsertProject(project);

      await viewModel.removeProject('remove');
      expect(viewModel.projectVMList.any((vm) => vm.project.id == 'remove'), isFalse);
    });

    test('clearAllProjectsCache empties the view model list', () async {
      final project = Project.empty().copyWith(id: 'cached');
      await viewModel.upsertProject(project);

      await viewModel.clearAllProjectsCache();
      expect(viewModel.projectVMList.isEmpty, isTrue);
    });
  });
}
