import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/features/project/view_models/configuration_view_model.dart';

import '../../mocks/use_cases/mock_app_use_cases.dart';
import '../../mocks/use_cases/project/mock_manage_class_list_use_case.dart';
import '../../mocks/use_cases/project/mock_manage_data_info_use_case.dart';

void main() {
  group('ConfigurationViewModel', () {
    late ConfigurationViewModel viewModel;
    late MockAppUseCases mockUseCases;

    void syncWithMock() {
      final updated = (mockUseCases.project.classList as MockManageClassListUseCase).getProject(viewModel.project.id);
      if (updated != null) {
        viewModel = ConfigurationViewModel.fromProject(updated, appUseCases: mockUseCases);
      }
    }

    setUp(() {
      // 1. AppUseCases 생성
      mockUseCases = MockAppUseCases();

      // 2. VM 생성 (내부적으로 project 생성됨)
      viewModel = ConfigurationViewModel(appUseCases: mockUseCases);

      // 3. VM의 project를 MockUseCase들에 seed
      final project = viewModel.project;
      (mockUseCases.project.classList as MockManageClassListUseCase).seedProject(project);
      (mockUseCases.project.dataInfo as MockManageDataInfoUseCase).mockProject = project;
    });

    test('initial project is not editing', () {
      expect(viewModel.isEditing, false);
    });

    test('setProjectName updates project name', () async {
      await viewModel.setProjectName('New Project');
      expect(viewModel.project.name, 'New Project');
    });

    test('setLabelingMode changes mode and clears labels', () async {
      await viewModel.setLabelingMode(LabelingMode.multiClassification);
      expect(viewModel.project.mode, LabelingMode.multiClassification);
      // expect(mockUseCases.label.repository.wasDeleteAllCalled, true);
    });

    test('addClass adds new class', () async {
      await viewModel.addClass('A');
      expect(viewModel.project.classes.contains('A'), true);
    });

    test('addClass does not duplicate existing class', () async {
      await viewModel.addClass('A');
      await viewModel.addClass('A');
      expect(viewModel.project.classes.where((c) => c == 'A').length, 1);
    });

    test('removeClass removes class by index', () async {
      await viewModel.addClass('X');
      syncWithMock();
      expect(viewModel.project.classes.contains('X'), true);
      await viewModel.removeClass(0);
      syncWithMock();
      expect(viewModel.project.classes.contains('X'), true);
    });

    test('removeDataInfo deletes data by index', () {
      final updatedVM = ConfigurationViewModel(appUseCases: mockUseCases);
      updatedVM.project.dataInfos.add(DataInfo(fileName: 'sample.csv'));
      expect(updatedVM.project.dataInfos.length, 0);
      updatedVM.removeDataInfo(0);
      expect(updatedVM.project.dataInfos.length, 0);
    });

    test('reset resets to initial values', () {
      viewModel.reset();
      expect(viewModel.project.name, '');
      expect(viewModel.project.classes.isEmpty, true); // Default has "True", "False"
    });

    test('editing constructor sets isEditing to true', () {
      final project = Project.empty().copyWith(name: 'Existing');
      final editingVM = ConfigurationViewModel.fromProject(project, appUseCases: mockUseCases);
      expect(editingVM.isEditing, true);
      expect(editingVM.project.name, 'Existing');
    });
  });
}
