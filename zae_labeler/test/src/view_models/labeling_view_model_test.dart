import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/view_models/labeling_view_model.dart';

import '../../mocks/mock_storage_helper.dart';
import '../../mocks/mock_path_provider.dart';
import '../../mocks/use_cases/mock_app_use_cases.dart';

void main() {
  setUpAll(() {
    MockPathProvider.setup();
  });

  group('LabelingViewModelFactory.createAsync', () {
    late MockStorageHelper mockStorage;
    late MockAppUseCases mockAppUseCases;

    setUp(() {
      mockStorage = MockStorageHelper();
      mockAppUseCases = MockAppUseCases();
    });

    Future<void> testCreation(LabelingMode mode, Type expectedType) async {
      final project = Project(
        id: 'test_project',
        name: '테스트 프로젝트',
        mode: mode,
        dataInfos: [DataInfo(id: '1', fileName: 'dummy.jpg')],
        classes: ['cat', 'dog'],
      );

      final viewModel = await LabelingViewModelFactory.createAsync(project, mockStorage, mockAppUseCases);

      expect(viewModel.runtimeType, expectedType);
      expect(viewModel.project.id, 'test_project');
      expect(viewModel.unifiedDataList.length, greaterThan(0));
    }

    test('creates ClassificationLabelingViewModel for singleClassification', () {
      return testCreation(LabelingMode.singleClassification, ClassificationLabelingViewModel);
    });

    test('creates ClassificationLabelingViewModel for multiClassification', () {
      return testCreation(LabelingMode.multiClassification, ClassificationLabelingViewModel);
    });

    test('creates CrossClassificationLabelingViewModel for crossClassification', () {
      return testCreation(LabelingMode.crossClassification, CrossClassificationLabelingViewModel);
    });

    test('creates SegmentationLabelingViewModel for singleClassSegmentation', () {
      return testCreation(LabelingMode.singleClassSegmentation, SegmentationLabelingViewModel);
    });

    test('creates SegmentationLabelingViewModel for multiClassSegmentation', () {
      return testCreation(LabelingMode.multiClassSegmentation, SegmentationLabelingViewModel);
    });
  });

  group('SegmentationLabelingViewModel', () {
    late MockAppUseCases mockAppUseCases;
    late MockStorageHelper mockStorage;
    late SegmentationLabelingViewModel segVM;

    setUp(() {
      mockStorage = MockStorageHelper();
      mockAppUseCases = MockAppUseCases();

      final project = Project(
        id: 'test-project',
        name: 'Test Project',
        mode: LabelingMode.multiClassSegmentation,
        dataInfos: [],
        classes: ['car', 'road'],
      );

      segVM = SegmentationLabelingViewModel(project: project, storageHelper: mockStorage, appUseCases: mockAppUseCases);
    });

    test('initial selected class is first in project.classes', () async {
      await segVM.postInitialize();
      expect(segVM.selectedClass, equals('car'));
    });

    test('setSelectedClass changes the selected class', () {
      segVM.setSelectedClass('road');
      expect(segVM.selectedClass, equals('road'));
    });

    test('updateSegmentationGrid replaces the entire grid', () {
      final newGrid = List.generate(32, (_) => List.filled(32, 0));
      newGrid[3][4] = 1;

      segVM.updateSegmentationGrid(newGrid);
      expect(segVM.labelGrid[3][4], equals(1));
    });

    test('saveCurrentGridAsLabel stores grid into labelModel', () async {
      segVM.setSelectedClass('car');
      segVM.updateSegmentationLabel(1, 2, 1);
      segVM.updateSegmentationLabel(2, 2, 1);

      await segVM.saveCurrentGridAsLabel();
      final label = segVM.currentLabelVM.labelModel.label as SegmentationData;
      final segment = label.segments['car'];

      expect(segment, isNotNull);
      expect(segment!.indices.contains((1, 2)), isTrue);
      expect(segment.indices.contains((2, 2)), isTrue);
    });

    test('restoreGridFromLabel reconstructs grid from label', () async {
      segVM.restoreGridFromLabel();

      expect(segVM.labelGrid[1][1], equals(1));
      expect(segVM.labelGrid[2][2], equals(1));
    });
  });
}
