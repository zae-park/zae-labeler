import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_entry.dart';
import 'package:zae_labeler/src/models/data_model.dart';
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
    test('✅ 프로젝트 저장 및 로드 테스트', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      // 프로젝트 저장
      await storageHelper.saveProjects([project]);

      // 프로젝트 로드
      final loadedProjects = await storageHelper.loadProjects();

      expect(loadedProjects.length, 1);
      expect(loadedProjects[0].id, project.id);
      expect(loadedProjects[0].name, project.name);
    });

    test('✅ 라벨 엔트리 저장 및 로드 테스트', () async {
      final labelEntry = LabelEntry(
        dataFilename: 'test_data.csv',
        dataPath: '/path/to/test_data.csv',
        singleClassification: SingleClassificationLabel(
          labeledAt: '2023-01-01T12:00:00Z',
          label: 'class1',
        ),
      );

      // 라벨 저장
      await storageHelper.saveLabelEntries('test_project', [labelEntry]);

      // 라벨 로드
      final loadedLabelEntries = await storageHelper.loadLabelEntries('test_project');

      expect(loadedLabelEntries.length, 1);
      expect(loadedLabelEntries[0].dataFilename, labelEntry.dataFilename);
      expect(loadedLabelEntries[0].singleClassification?.label, 'class1');
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

    test('✅ 라벨 ZIP 다운로드 테스트', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      final labelEntry = LabelEntry(
        dataFilename: 'test_data.csv',
        dataPath: '/path/to/test_data.csv',
        singleClassification: SingleClassificationLabel(
          labeledAt: '2023-01-01T12:00:00Z',
          label: 'class1',
        ),
      );

      final dataPath = DataPath(
        fileName: 'test_data.csv',
        base64Content: base64Encode(utf8.encode('data1,data2,data3')),
      );

      // ZIP 파일 다운로드
      final zipPath = await storageHelper.downloadLabelsAsZip(
        project,
        [labelEntry],
        [dataPath],
      );

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
  });
}
