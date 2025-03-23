import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/view_models/project_list_view_model.dart';

void main() {
  group('ProjectListViewModel', () {
    late ProjectListViewModel viewModel;

    setUp(() {
      viewModel = ProjectListViewModel();
    });

    test('add and remove project', () {
      final project = Project(
        id: '123',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['A'],
      );

      viewModel.saveProject(project);
      expect(viewModel.projects.length, equals(1));

      viewModel.removeProject(project.id);
      expect(viewModel.projects.length, equals(0));
    });

    test('update existing project', () {
      final project = Project(
        id: '456',
        name: 'Old Name',
        mode: LabelingMode.singleClassification,
        classes: ['X'],
      );

      viewModel.saveProject(project);

      final updated = project.copyWith(name: 'New Name');
      viewModel.updateProject(null, updated);

      expect(viewModel.projects.first.name, equals('New Name'));
    });
  });
}
