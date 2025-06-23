import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/view_models/managers/label_input_mapper.dart';
import 'package:zae_labeler/src/view_models/sub_view_models/segmentation_label_view_model.dart';

import '../../../mocks/use_cases/label/mock_label_use_cases.dart';

void main() {
  group('SegmentationLabelViewModel', () {
    late SegmentationLabelViewModel viewModel;

    setUp(() {
      viewModel = SegmentationLabelViewModel(
        projectId: 'test_project',
        dataId: 'sample_data',
        dataFilename: 'image.png',
        dataPath: '/mock/path/image.png',
        mode: LabelingMode.singleClassSegmentation,
        labelModel: SingleClassSegmentationLabelModel(
          dataId: 'sample_data',
          dataPath: '/mock/path/image.png',
          label: SingleClassSegmentationLabelModel.empty().label,
          labeledAt: DateTime(2023),
        ),
        labelUseCases: MockLabelUseCases(),
        labelInputMapper: SingleSegmentationInputMapper(),
      );
    });

    test('addPixel should update label with new pixel', () async {
      await viewModel.addPixel(3, 5, 'cat');

      final labelData = viewModel.labelModel.label!;
      expect(labelData.getPixel(3, 5), equals('cat'));
    });

    test('removePixel should remove pixel from label', () async {
      await viewModel.addPixel(1, 2, 'dog');
      await viewModel.removePixel(1, 2);

      final labelData = viewModel.labelModel.label!;
      expect(labelData.getPixel(1, 2), isNull);
    });

    test('addPixel followed by removePixel should leave no label', () async {
      await viewModel.addPixel(10, 10, 'tree');
      await viewModel.removePixel(10, 10);

      final labelData = viewModel.labelModel.label!;
      expect(labelData.getPixel(10, 10), isNull);
    });
  });
}
