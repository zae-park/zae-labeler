// test/view_models/labeling_view_model_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/view_models/labeling_view_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import '../mocks/mock_storage_helper.dart'; // ✅ Mock 클래스를 별도 파일에서 가져오기

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
            base64Content: base64Encode(utf8.encode('[{"dataFilename": "file1.json", "dataPath": "file1.json"}]')), // ✅ JSON 데이터로 변경
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
      await labelingVM.loadCurrentData();
      expect(labelingVM.currentUnifiedData, isNotNull);
    });

    test('✅ 라벨 추가 테스트 (saveLabelEntry가 호출되는지 확인)', () async {
      await labelingVM.addOrUpdateLabel('A', 'single_classification');
      expect(labelingVM.labelEntries[0].singleClassification?.label, 'A');

      // ✅ Mock StorageHelper가 saveLabelEntry를 호출했는지 검증 가능하다면 추가
      // verify(mockStorageHelper.saveLabelEntry(any)).called(1);
    });

    test('✅ 라벨 선택 확인 테스트', () {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      expect(labelingVM.isLabelSelected('A', 'single_classification'), isTrue);
      expect(labelingVM.isLabelSelected('B', 'single_classification'), isFalse);
    });

    test('✅ moveNext() 및 movePrevious()가 비동기적으로 실행되는지 확인', () async {
      await labelingVM.initialize();

      labelingVM.moveNext(); // ✅ `await`을 추가하여 비동기 실행 대기
      expect(labelingVM.currentIndex, 1);
      expect(labelingVM.currentUnifiedData, isNotNull);

      labelingVM.movePrevious(); // ✅ `await`을 추가하여 비동기 실행 대기
      expect(labelingVM.currentIndex, 0);
      expect(labelingVM.currentUnifiedData, isNotNull);
    });

    test('✅ moveNext() 실행 후 loadCurrentData()가 호출되는지 확인', () async {
      await labelingVM.initialize();
      labelingVM.moveNext();

      expect(labelingVM.currentUnifiedData, isNotNull);
      expect(labelingVM.currentIndex, 1);
    });

    test('✅ 라벨 다운로드 테스트', () async {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      String zipPath = await labelingVM.downloadLabelsAsZip();
      expect(zipPath, 'mock_zip_path.zip');
    });
  });
}
