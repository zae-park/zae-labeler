import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/project/project_use_cases.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';
import '../../mocks/use_cases/project/mock_project_use_cases.dart';

void main() {
  group('ProjectListViewModel', () {
    late ProjectUseCases mockProjectUseCases;
    late ProjectListViewModel vm;

    final sampleProject = Project(
      id: 'test1',
      name: 'Sample Project',
      mode: LabelingMode.singleClassification,
      classes: [],
    );

    setUp(() {
      mockProjectUseCases = MockProjectUseCases();
      vm = ProjectListViewModel(projectUseCases: mockProjectUseCases);
    });

    // test('upsertProject adds new ProjectViewModel', () async {
    //   await vm.upsertProject(sampleProject);

    //   expect(vm.projectVMList.length, 1);
    //   expect(vm.projectVMList.first.project.name, 'Sample Project');
    // });

    // test('removeProject deletes a ProjectViewModel', () async {
    //   await vm.upsertProject(sampleProject);
    //   await vm.removeProject('test1');

    //   expect(vm.projectVMList.any((vm) => vm.project.id == 'test1'), false);
    // });

    // test('upsertProject updates existing ProjectViewModel', () async {
    //   await vm.upsertProject(sampleProject);

    //   final updated = sampleProject.copyWith(name: 'Updated Name');
    //   await vm.upsertProject(updated);

    //   expect(vm.projectVMList.first.project.name, 'Updated Name');
    // });

    // test('clearAllProjectsCache clears all ViewModels', () async {
    //   await vm.upsertProject(sampleProject);
    //   await vm.clearAllProjectsCache();

    //   expect(vm.projectVMList.isEmpty, true);
    // });
  });
}
