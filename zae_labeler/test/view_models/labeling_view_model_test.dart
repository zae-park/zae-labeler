import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
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
        dataPaths: [DataPath(fileName: 'file1.csv', base64Content: 'MTIzLDQ1Niw3ODk='), DataPath(fileName: 'file2.csv', base64Content: 'MTAwLDIwMCwzMDA=')],
        labelEntries: [],
      );
      labelingVM = LabelingViewModel(project: project, storageHelper: mockStorageHelper);
    });

    test('✅ 초기화 테스트 - labelEntries가 프로젝트와 동일해야 함', () async {
      await labelingVM.initialize();
      expect(labelingVM.labelEntries, equals(project.labelEntries));
    });

    test('✅ 데이터 상태 업데이트 테스트', () async {
      await labelingVM.updateLabelState();
      expect(labelingVM.currentUnifiedData, isNotNull);
    });

    test('✅ 라벨 추가 테스트', () {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      expect(labelingVM.labelEntries[0].singleClassification?.label, 'A');
    });

    test('✅ 라벨 선택 확인 테스트', () {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      expect(labelingVM.isLabelSelected('A', 'single_classification'), isTrue);
      expect(labelingVM.isLabelSelected('B', 'single_classification'), isFalse);
    });

    test('✅ 이전/다음 데이터 이동 테스트', () {
      expect(labelingVM.currentIndex, 0);

      labelingVM.moveNext();
      expect(labelingVM.currentIndex, 1);

      labelingVM.movePrevious();
      expect(labelingVM.currentIndex, 0);
    });

    test('✅ 라벨 다운로드 테스트', () async {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      String zipPath = await labelingVM.downloadLabelsAsZip();
      expect(zipPath, 'mock_zip_path.zip');
    });
  });
}
