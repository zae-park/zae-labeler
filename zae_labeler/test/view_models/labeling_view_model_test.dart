// test/view_models/labeling_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/view_models/labeling_view_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import '../mocks/mock_storage_helper.dart';

void main() {
  group('LabelingViewModel', () {
    final project = Project(
      id: 'proj1',
      name: 'Test',
      mode: LabelingMode.singleClassification,
      classes: ['A', 'B'],
      dataPaths: [DataPath(fileName: 'sample.txt', filePath: '/sample.txt')],
    );

    late LabelingViewModel viewModel;

    setUp(() {
      viewModel = LabelingViewModel(project: project, storageHelper: MockStorageHelper());
    });

    test('initialization sets first data', () async {
      await viewModel.initialize();
      expect(viewModel.currentDataFileName, equals('sample.txt'));
    });

    test('toggle label updates selection', () {
      viewModel.toggleLabel('A');
      expect(viewModel.selectedLabels.contains('A'), isTrue);
      viewModel.toggleLabel('A');
      expect(viewModel.selectedLabels.contains('A'), isFalse);
    });

    test('navigation updates index', () async {
      await viewModel.initialize();
      viewModel.project.dataPaths.add(DataPath(fileName: 'next.txt', filePath: '/next.txt'));

      await viewModel.moveNext();
      expect(viewModel.currentIndex, equals(1));

      await viewModel.movePrevious();
      expect(viewModel.currentIndex, equals(0));
    });
  });

  test('label is preserved across reloads', () async {
    final storage = MockStorageHelper();

    // 🛠 테스트 전용 프로젝트 정의
    final project = Project(
      id: 'proj1',
      name: 'Test',
      mode: LabelingMode.singleClassification,
      classes: ['A', 'B'],
      dataPaths: [DataPath(fileName: 'sample.txt', filePath: '/sample.txt')],
    );

    // 1️⃣ 첫 번째 ViewModel → label 저장
    final firstVM = LabelingViewModel(project: project, storageHelper: storage);
    await firstVM.initialize();
    await firstVM.addOrUpdateLabel('A');

    // 2️⃣ 두 번째 ViewModel → 같은 프로젝트로 다시 로딩
    final secondVM = LabelingViewModel(project: project, storageHelper: storage);
    await secondVM.initialize();

    final label = secondVM.currentLabelVM.labelModel;

    // ✅ 검증
    expect(label is SingleClassificationLabelModel, isTrue);
    expect((label as SingleClassificationLabelModel).label, equals('A'));
  });
}
