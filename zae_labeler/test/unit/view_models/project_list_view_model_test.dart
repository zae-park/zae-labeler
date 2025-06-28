import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';

import '../../mocks/repositories/mock_project_repository.dart';
import '../../mocks/use_cases/project/mock_project_use_cases.dart';

void main() {
  group('ProjectListViewModel', () {
    late MockProjectRepository repo;
    late MockProjectUseCases mockUseCases;
    late ProjectListViewModel viewModel;

    setUp(() {
      repo = MockProjectRepository();
      mockUseCases = MockProjectUseCases(repository: repo);
      viewModel = ProjectListViewModel(projectUseCases: mockUseCases);
    });

    test('loadProjects populates projectVMList', () async {
      // ✅ repo에 직접 저장
      await repo.saveAll([
        Project.empty().copyWith(id: 'p1', name: 'Test1'),
        Project.empty().copyWith(id: 'p2', name: 'Test2'),
      ]);

      // ✅ viewModel을 다시 생성하여 mockUseCases 연결
      viewModel = ProjectListViewModel(projectUseCases: mockUseCases);

      await viewModel.loadProjects();

      expect(viewModel.projectVMList.length, 2);
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
