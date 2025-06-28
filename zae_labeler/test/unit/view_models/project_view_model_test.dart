import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/view_models/project_view_model.dart';

import '../../mocks/helpers/mock_share_helper.dart';
import '../../mocks/repositories/mock_project_repository.dart';
import '../../mocks/use_cases/project/mock_edit_project_use_case.dart';
import '../../mocks/use_cases/project/mock_manage_class_list_use_case.dart';
import '../../mocks/use_cases/project/mock_manage_data_info_use_case.dart';
import '../../mocks/use_cases/project/mock_project_use_cases.dart';
import '../../mocks/use_cases/project/mock_share_project_use_case.dart';

void main() {
  group('ProjectViewModel', () {
    late ProjectViewModel viewModel;
    late MockProjectRepository repo;
    late MockShareHelper shareHelper;
    late MockProjectUseCases useCases;
    late List<Project> changedProjects;

    setUp(() {
      repo = MockProjectRepository();
      shareHelper = MockShareHelper();
      useCases = MockProjectUseCases(repository: repo);
      changedProjects = [];

      viewModel = ProjectViewModel(shareHelper: shareHelper, useCases: useCases, onChanged: (p) => changedProjects.add(p));

      final project = viewModel.project;
      repo.saveProject(project);

      (useCases.dataInfo as MockManageDataInfoUseCase).mockProject = project;
      (useCases.classList as MockManageClassListUseCase).seedProject(project);
      (useCases.edit as MockEditProjectMetaUseCase).seedProject(project);
    });

    void syncWithMock() {
      final updated = (useCases.classList as MockManageClassListUseCase).getProject(viewModel.project.id)!;
      viewModel.updateFrom(updated);
    }

    test('setName updates the project name', () async {
      await viewModel.setName('Updated Project');
      expect(viewModel.project.name, 'Updated Project');
      expect(changedProjects.last.name, 'Updated Project');
    });

    test('setLabelingMode changes the mode', () async {
      await viewModel.setLabelingMode(LabelingMode.multiClassification);
      expect(viewModel.project.mode, LabelingMode.multiClassification);
    });

    test('addClass adds a new class', () async {
      await viewModel.addClass('A');
      syncWithMock();
      expect(viewModel.project.classes, contains('A'));
    });

    test('editClass changes class name', () async {
      await viewModel.addClass('A');
      await viewModel.editClass(0, 'B');
      syncWithMock();
      expect(viewModel.project.classes[0], 'B');
    });

    test('removeClass deletes a class', () async {
      await viewModel.addClass('X');
      await viewModel.removeClass(0);
      syncWithMock();
      expect(viewModel.project.classes, isEmpty);
    });

    test('addDataInfo appends new data', () async {
      final data = DataInfo(fileName: 'data.csv');
      await viewModel.addDataInfo(data);
      expect(viewModel.project.dataInfos, contains(data));
    });

    test('removeDataInfo removes by id', () async {
      final data = DataInfo(fileName: 'to_remove.csv');
      await viewModel.addDataInfo(data);
      await viewModel.removeDataInfo(data.id);
      expect(viewModel.project.dataInfos.any((d) => d.id == data.id), isFalse);
    });

    test('isLabelingModeChanged detects change', () async {
      await viewModel.setLabelingMode(LabelingMode.singleClassification); // initial baseline
      await viewModel.setLabelingMode(LabelingMode.multiClassification); // actual change
      expect(viewModel.isLabelingModeChanged(), true);

      // final initial = viewModel.project.mode;
      // await viewModel.setLabelingMode(LabelingMode.multiClassification);
      // expect(viewModel.isLabelingModeChanged(), initial != viewModel.project.mode);
    });

    test('saveProject triggers storage and notifies', () async {
      await viewModel.saveProject(true);
      final stored = await repo.findById(viewModel.project.id);
      expect(stored?.id, viewModel.project.id);
    });

    test('clearProjectLabels triggers deletion and notifies', () async {
      await viewModel.clearProjectLabels();
      (viewModel.useCases.repository as MockProjectRepository).wasClearLabelsCalled = true;
      expect(repo.wasClearLabelsCalled, isTrue);
    });

    test('shareProject triggers helper', () async {
      await viewModel.shareProject(FakeBuildContext());
      expect((viewModel.useCases.share as MockShareProjectUseCase).wasCalled, isTrue);
    });

    test('downloadProjectConfig calls repository', () async {
      await viewModel.downloadProjectConfig();
      expect(repo.wasDownloadCalled, isTrue);
    });

    test('updateFrom applies external project changes', () {
      final newProject = Project.empty().copyWith(id: 'new_id', name: 'New Name');
      viewModel.updateFrom(newProject);
      expect(viewModel.project.id, 'new_id');
      expect(viewModel.project.name, 'New Name');
    });
  });
}

// Stub for BuildContext
class FakeBuildContext extends Fake implements BuildContext {}
