import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_models/classification_label_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

import '../mocks/mock_path_provider.dart';

void main() {
  // ✅ 테스트 실행 전에 Flutter 바인딩을 초기화
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageHelper storageHelper;
  late Directory tempDir;

  setUpAll(() async {
    MockPathProvider.setup();
  });

  setUp(() async {
    storageHelper = StorageHelper();
    tempDir = Directory.systemTemp.createTempSync(); // ✅ 임시 디렉토리 생성
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true); // ✅ 테스트 후 파일 삭제
    }
  });

  group('StorageHelperImpl', () {
    test('✅ 프로젝트 설정 저장 및 로드 테스트', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      // 프로젝트 저장
      await storageHelper.saveProjectConfig([project]);

      // 프로젝트 로드
      final loadedProjects = await storageHelper.loadProjectFromConfig('projects.json');

      expect(loadedProjects.length, 1);
      expect(loadedProjects[0].id, project.id);
      expect(loadedProjects[0].name, project.name);
    });

    test('✅ 단일 라벨 저장 및 로드 테스트', () async {
      final label = SingleClassificationLabelModel(
        labeledAt: DateTime.now(),
        label: 'class1',
      );

      const dataPath = '/path/to/test_data.csv';

      // 라벨 저장
      await storageHelper.saveLabelData('test_project', dataPath, label);

      // 라벨 로드
      final loadedLabel = await storageHelper.loadLabelData('test_project', dataPath, LabelingMode.singleClassification);

      expect(loadedLabel is SingleClassificationLabelModel, true);
      expect((loadedLabel as SingleClassificationLabelModel).label, 'class1');
    });

    test('✅ 모든 라벨 저장 및 로드 테스트', () async {
      final List<LabelModel> labels = [
        SingleClassificationLabelModel(labeledAt: DateTime.now(), label: 'class1'),
        MultiClassificationLabelModel(labeledAt: DateTime.now(), label: ['class1', 'class2']),
      ];

      // ✅ `saveAllLabels` 호출 시 타입 변환 적용
      await storageHelper.saveAllLabels('test_project', labels);

      // 모든 라벨 로드
      final loadedLabels = await storageHelper.loadAllLabels('test_project');

      expect(loadedLabels.length, labels.length);
      expect(loadedLabels[0] is SingleClassificationLabelModel, true);
      expect(loadedLabels[1] is MultiClassificationLabelModel, true);
    });

    test('✅ 프로젝트 설정 다운로드 테스트', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      // 다운로드 실행
      final filePath = await storageHelper.downloadProjectConfig(project);
      final file = File(filePath);

      expect(await file.exists(), true); // 파일이 존재하는지 확인

      // 파일 내용 확인
      final content = await file.readAsString();
      final loadedProject = Project.fromJson(jsonDecode(content));

      expect(loadedProject.id, project.id);
      expect(loadedProject.name, project.name);

      file.deleteSync(); // ✅ 테스트 후 파일 삭제
    });

    test('✅ 모든 라벨 ZIP 내보내기 테스트', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      final List<LabelModel> labels = [
        SingleClassificationLabelModel(labeledAt: DateTime.now(), label: 'class1'),
        MultiClassificationLabelModel(labeledAt: DateTime.now(), label: ['class1', 'class2']),
      ];

      final dataPath = DataPath(
        fileName: 'test_data.csv',
        base64Content: base64Encode(utf8.encode('data1,data2,data3')),
      );

      // ZIP 파일 내보내기 (기존 `downloadLabelsAsZip` → `exportAllLabels`)
      final zipPath = await storageHelper.exportAllLabels(project, labels, [dataPath]);

      final zipFile = File(zipPath);
      expect(await zipFile.exists(), true); // 파일 존재 여부 확인

      // ZIP 파일 압축 해제하여 확인
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      expect(archive.files.length, 2);
      expect(archive.files.any((file) => file.name == 'labels.json'), true);
      expect(archive.files.any((file) => file.name == 'test_data.csv'), true);

      zipFile.deleteSync(); // ✅ 테스트 후 ZIP 파일 삭제
    });

    test('✅ 외부 라벨 가져오기 테스트', () async {
      // ✅ 테스트 환경에서 가상의 JSON 데이터 생성
      final directory = Directory.systemTemp.createTempSync();
      final file = File('${directory.path}/labels_import.json');
      final jsonData = jsonEncode([
        {
          'mode': 'SingleClassificationLabelModel',
          'labeled_at': DateTime.now().toIso8601String(),
          'label_data': {'label': 'class1'}
        },
        {
          'mode': 'MultiClassificationLabelModel',
          'labeled_at': DateTime.now().toIso8601String(),
          'label_data': {
            'labels': ['class1', 'class2']
          }
        },
      ]);
      await file.writeAsString(jsonData);

      // ✅ 임포트 실행 (importAllLabels)
      final loadedLabels = await storageHelper.importAllLabels();

      expect(loadedLabels.length, 2);
      expect(loadedLabels[0] is SingleClassificationLabelModel, true);
      expect(loadedLabels[1] is MultiClassificationLabelModel, true);

      // ✅ 테스트 후 파일 삭제
      file.deleteSync();
    });
  });
}
