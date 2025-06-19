import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/domain/label/label_use_cases.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/sub_models/segmentation_label_model.dart';
import 'package:zae_labeler/src/view_models/label_view_model.dart';

import '../../../mocks/mock_label_repository.dart';
import '../../../mocks/mock_storage_helper.dart';

void main() {
  group('SegmentationLabelModel', () {
    late SegmentationLabelViewModel vm;

    setUp(() {
      vm = SegmentationLabelViewModel(
          projectId: "test-project",
          dataId: "test-data",
          dataFilename: "test-data",
          dataPath: "test-dataPath",
          mode: LabelingMode.singleClassSegmentation,
          labelModel: SingleClassSegmentationLabelModel.empty(),
          labelUseCases: LabelUseCases.from(MockLabelRepository(storageHelper: MockStorageHelper())),
          labelInputMapper: LabelInputMapperFactory.create(LabelingMode.singleClassSegmentation));
    });

    test('SingleClassSegmentationLabelModel pixel add/remove and status', () async {
      final model = SingleClassSegmentationLabelModel.empty();

      expect(model.isLabeled, isFalse);

      await vm.addPixel(1, 1, "sample");
      expect(vm.labelModel.label.segments['sample']!.containsPixel(1, 1), isTrue);
      expect(vm.labelModel.isLabeled, isTrue);

      await vm.removePixel(1, 1);
      expect(vm.labelModel.label.segments['sample'], isNull);
      expect(vm.labelModel.isLabeled, isFalse);
    });

    test('MultiClassSegmentationLabelModel pixel add/remove and status', () async {
      await vm.addPixel(2, 2, 'person');
      expect(vm.labelModel.label.segments['person']?.containsPixel(2, 2), isTrue);
      expect(vm.labelModel.isLabeled, isTrue);

      await vm.removePixel(2, 2);
      expect(vm.labelModel.label.segments['person'], isNull);
      expect(vm.labelModel.isLabeled, isFalse);
    });
  });
}
