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

    test('✅ 라벨 다운로드 테스트', () async {
      labelingVM.addOrUpdateLabel('A', 'single_classification');
      String zipPath = await labelingVM.downloadLabelsAsZip();
      expect(zipPath, 'mock_zip_path.zip');
    });
  });
}
