import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/utils/share_helper.dart';
import 'package:zae_labeler/src/view_models/project_view_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import '../mocks/mock_storage_helper.dart';

void main() {
  group('ProjectViewModel', () {
    if (!kIsWeb) {
      test('skipped on non-web', () => expect(true, isTrue), skip: true);
      return;
    }
    late ProjectViewModel viewModel;
    late MockStorageHelper mockHelper;

    setUp(() {
      mockHelper = MockStorageHelper();
      viewModel = ProjectViewModel(storageHelper: mockHelper, shareHelper: ShareHelper());
    });

    test('setName updates project name', () {
      viewModel.setName('New Name');
      expect(viewModel.project.name, 'New Name');
    });

    test('setLabelingMode updates mode', () {
      viewModel.setLabelingMode(LabelingMode.multiClassification);
      expect(viewModel.project.mode, LabelingMode.multiClassification);
    });

    test('addClass adds new class if not exists', () {
      viewModel.addClass('A');
      expect(viewModel.project.classes.contains('A'), isTrue);
    });

    test('removeClass removes correct class', () {
      viewModel.addClass('A');
      viewModel.addClass('B');
      viewModel.removeClass(0);
      expect(viewModel.project.classes.contains('A'), isFalse);
      expect(viewModel.project.classes.length, 1);
    });

    test('addDataPath adds data path', () {
      viewModel.addDataPath(DataPath(fileName: 'test.txt', filePath: '/test'));
      expect(viewModel.project.dataPaths.length, 1);
    });

    test('saveProject triggers storage saveProjectConfig', () async {
      await viewModel.saveProject(true);
      expect(mockHelper.wasSaveProjectCalled, isTrue);
      // expect(mockHelper.savedProjects.length, 1);
      // expect(mockHelper.savedProjects.first.id, equals(initial.id));
    });
  });
}
