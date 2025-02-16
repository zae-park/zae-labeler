import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/labeling_view_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import '../mocks/mock_storage_helper.dart';
import '../mocks/mock_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LabelingViewModel Tests', () {
    late Project project;
    late LabelingViewModel labelingVM;
    late MockStorageHelper mockStorageHelper;

    setUp(() {
      mockStorageHelper = MockStorageHelper();
      project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['A', 'B', 'C'],
        dataPaths: [
          DataPath(
            fileName: 'file1.json',
            base64Content: base64Encode(utf8.encode('[{"dataFilename": "file1.json", "dataPath": "file1.json"}]')),
          ),
          DataPath(fileName: 'file2.csv', base64Content: 'MTAwLDIwMCwzMDA=')
        ],
        labelEntries: [],
      );
      labelingVM = LabelingViewModel(project: project, storageHelper: mockStorageHelper);
    });

    test('✅ 초기화 테스트 - labelEntries가 프로젝트와 동일해야 함', () async {
      await labelingVM.initialize();
      expect(labelingVM.labelEntries, equals(project.labelEntries));
      expect(labelingVM.unifiedDataList.isEmpty, isTrue);
      expect(labelingVM.currentUnifiedData, isNotNull);
    });

    test('✅ 초기화 후 첫 번째 데이터가 로드되는지 확인', () async {
      await labelingVM.initialize();
      expect(labelingVM.currentUnifiedData, isNotNull);
      expect(labelingVM.currentDataFileName, 'file1.json');
    });

    test('✅ loadCurrentData()가 올바르게 실행되는지 확인', () async {
      await labelingVM.initialize();
      await labelingVM.loadCurrentData();
      expect(labelingVM.currentUnifiedData, isNotNull);
    });

    test('✅ 라벨 추가 테스트 (saveLabelEntry가 호출되는지 확인)', () async {
      await labelingVM.initialize();
      await labelingVM.addOrUpdateLabel('A', LabelingMode.singleClassification);

      expect(labelingVM.labelEntries.any((entry) => entry.dataFilename == labelingVM.currentDataFileName && entry.singleClassification?.label == 'A'), isTrue);
    });

    test('✅ 라벨 선택 확인 테스트', () async {
      await labelingVM.initialize();
      await labelingVM.addOrUpdateLabel('A', LabelingMode.singleClassification);

      expect(labelingVM.isLabelSelected('A', LabelingMode.singleClassification), isTrue);
      expect(labelingVM.isLabelSelected('B', LabelingMode.singleClassification), isFalse);
    });

    test('✅ 라벨이 없는 경우 기본값 반환 확인', () async {
      await labelingVM.initialize();
      expect(labelingVM.isLabelSelected('X', LabelingMode.singleClassification), isFalse);
    });

    test('✅ moveNext() 실행 후 loadCurrentData()가 호출되는지 확인', () async {
      await labelingVM.initialize();
      await labelingVM.moveNext();

      expect(labelingVM.currentUnifiedData, isNotNull);
      expect(labelingVM.currentIndex, 1);
    });

    test('✅ movePrevious() 실행 후 loadCurrentData()가 호출되는지 확인', () async {
      await labelingVM.initialize();
      await labelingVM.movePrevious();

      expect(labelingVM.currentUnifiedData, isNotNull);
      expect(labelingVM.currentIndex, 0);
    });

    test('✅ 라벨 다운로드 테스트', () async {
      await labelingVM.initialize();
      await labelingVM.addOrUpdateLabel('A', LabelingMode.singleClassification);

      String zipPath = await labelingVM.downloadLabelsAsZip();
      expect(zipPath, 'mock_zip_path.zip');
    });
  });
}
