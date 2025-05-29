import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/project_view_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import '../../mocks/mock_project_repository.dart';
import '../../mocks/mock_share_helper.dart';

void main() {
  group('ProjectViewModel (Refactored)', () {
    late ProjectViewModel viewModel;
    late MockProjectRepository mockRepository;
    late MockShareHelper mockShare;

    setUp(() {
      mockRepository = MockProjectRepository();
      mockShare = MockShareHelper();
      viewModel = ProjectViewModel(repository: mockRepository, shareHelper: mockShare);
    });

    test('setName updates project name', () {
      viewModel.setName('New Name');
      expect(viewModel.project.name, equals('New Name'));
    });

    test('setLabelingMode updates mode', () async {
      await viewModel.setLabelingMode(LabelingMode.multiClassification);
      expect(viewModel.project.mode, LabelingMode.multiClassification);
    });

    test('addClass adds new label class', () {
      viewModel.addClass('Class A');
      expect(viewModel.project.classes.contains('Class A'), isTrue);
    });

    test('removeClass removes class by index', () {
      viewModel.addClass('X');
      viewModel.addClass('Y');
      viewModel.removeClass(0);
      expect(viewModel.project.classes, contains('Y'));
      expect(viewModel.project.classes, isNot(contains('X')));
    });

    test('addDataInfo appends dataInfo to list', () {
      final info = DataInfo(fileName: 'abc.txt', filePath: '/tmp/abc.txt');
      viewModel.addDataInfo(info);
      expect(viewModel.project.dataInfos.length, 1);
      expect(viewModel.project.dataInfos.first.fileName, 'abc.txt');
    });

    test('saveProject calls repository.saveProject', () async {
      await viewModel.saveProject(true);
      expect(mockRepository.wasSaveProjectCalled, isTrue);
    });

    test('deleteProject calls repository.deleteById', () async {
      viewModel.setName('To Be Deleted');
      await viewModel.deleteProject();
      expect(mockRepository.wasDeleteCalled, isTrue);
    });

    test('clearProjectData calls deleteProjectLabels', () async {
      await viewModel.clearProjectData();
      expect(mockRepository.wasLabelDeleted, isTrue);
    });
  });
}
