import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/view_models/sub_view_models/segmentation_labeling_view_model.dart';
import '../mocks/mock_storage_helper.dart';
import '../mocks/mock_path_provider.dart';

void main() {
  setUpAll(() {
    MockPathProvider.setup();
  });
  group('SegmentationLabelingViewModel', () {
    late SegmentationLabelingViewModel viewModel;

    setUp(() {
      final project = Project(
        id: 'test-project',
        name: 'Test Project',
        mode: LabelingMode.multiClassSegmentation,
        dataPaths: [],
        classes: ['car', 'road'],
      );

      viewModel = SegmentationLabelingViewModel(
        project: project,
        storageHelper: MockStorageHelper(), // ✅ 실제 저장은 Mock
      );
    });

    test('initial selected class is first in project.classes', () async {
      await viewModel.postInitialize();
      expect(viewModel.selectedClass, equals('car'));
    });

    test('setSelectedClass changes the selected class', () {
      viewModel.setSelectedClass('road');
      expect(viewModel.selectedClass, equals('road'));
    });

    test('addPixel updates label model and grid state', () {
      viewModel.setSelectedClass('car');
      viewModel.addPixel(5, 5);

      final label = viewModel.currentLabelVM.labelModel.label as SegmentationData;
      expect(label.segments.containsKey('car'), isTrue);
      expect(label.segments['car']!.indices.contains((5, 5)), isTrue);
    });

    test('removePixel removes the pixel from the segment', () {
      viewModel.setSelectedClass('road');
      viewModel.addPixel(10, 10);
      viewModel.removePixel(10, 10);

      final label = viewModel.currentLabelVM.labelModel.label as SegmentationData;
      expect(label.segments['road']?.indices.contains((10, 10)), isNull);
    });

    test('updateSegmentationGrid replaces the entire grid', () {
      final newGrid = List.generate(32, (_) => List.filled(32, 0));
      newGrid[3][4] = 1;

      viewModel.updateSegmentationGrid(newGrid);
      expect(viewModel.labelGrid[3][4], equals(1));
    });

    test('saveCurrentGridAsLabel stores grid into labelModel', () async {
      viewModel.setSelectedClass('car');
      viewModel.updateSegmentationLabel(1, 2, 1);
      viewModel.updateSegmentationLabel(2, 2, 1);

      await viewModel.saveCurrentGridAsLabel();

      final label = viewModel.currentLabelVM.labelModel.label as SegmentationData;
      final segment = label.segments['car'];

      expect(segment, isNotNull);
      expect(segment!.indices.contains((1, 2)), isTrue);
      expect(segment.indices.contains((2, 2)), isTrue);
    });

    test('restoreGridFromLabel reconstructs grid from label', () async {
      // 가짜 세그먼트 구성
      final fakeLabel = SegmentationData(segments: {
        'car': Segment(indices: {(1, 1), (2, 2)}, classLabel: 'car'),
      });

      viewModel.currentLabelVM.updateLabel(fakeLabel);
      viewModel.restoreGridFromLabel();

      expect(viewModel.labelGrid[1][1], equals(1));
      expect(viewModel.labelGrid[2][2], equals(1));
    });
  });
}
