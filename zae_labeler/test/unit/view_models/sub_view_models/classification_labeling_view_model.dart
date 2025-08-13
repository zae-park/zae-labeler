import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/data_model.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/classification_labeling_view_model.dart';

import '../../../mocks/helpers/mock_storage_helper.dart';
import '../../../mocks/use_cases/mock_app_use_cases.dart';

void main() {
  group('ClassificationLabelingViewModel', () {
    late ClassificationLabelingViewModel viewModel;
    final mockProject = Project(
      id: 'test_project',
      name: 'Test Project',
      mode: LabelingMode.singleClassification,
      classes: [],
    );

    final unifiedDataList = List.generate(3, (i) => UnifiedData.empty());

    setUp(() {
      viewModel = ClassificationLabelingViewModel(
        project: mockProject,
        storageHelper: MockStorageHelper(),
        appUseCases: MockAppUseCases(),
        initialDataList: unifiedDataList,
      );
    });

    test('initialization loads unifiedDataList and current label', () async {
      await viewModel.initialize();
      expect(viewModel.unifiedDataList.length, 3);
      expect(viewModel.currentUnifiedData.dataId, 'd0');
      expect(viewModel.isInitialized, true);
    });

    test('toggleLabel updates label selection', () async {
      await viewModel.initialize();
      await viewModel.toggleLabel('label1');

      final label = viewModel.currentLabelVM.labelModel.label;
      expect(label, 'label1');
      expect(viewModel.isLabelSelected('label1'), true);
    });

    test('moveNext and movePrevious updates currentIndex', () async {
      await viewModel.initialize();
      expect(viewModel.currentIndex, 0);

      await viewModel.moveNext();
      expect(viewModel.currentIndex, 1);

      await viewModel.movePrevious();
      expect(viewModel.currentIndex, 0);
    });

    test('progress counts are correct after labeling', () async {
      await viewModel.initialize();
      expect(viewModel.completeCount, 0);

      await viewModel.toggleLabel('labelA');
      expect(viewModel.completeCount, 1);
      expect(viewModel.progressRatio, 1 / 3);
    });
  });
}
