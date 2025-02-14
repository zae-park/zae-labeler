import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_entry.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

void main() {
  late StorageHelper storageHelper;

  setUp(() async {
    storageHelper = StorageHelper();
  });

  group('StorageHelperImpl', () {
    test('Save and Load Projects', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      // Save the project
      await storageHelper.saveProjects([project]);

      // Load the project
      final loadedProjects = await storageHelper.loadProjects();

      expect(loadedProjects.length, 1);
      expect(loadedProjects[0].id, project.id);
      expect(loadedProjects[0].name, project.name);
    });

    test('Save and Load Label Entries', () async {
      final labelEntry = LabelEntry(
        dataFilename: 'test_data.csv',
        dataPath: '/path/to/test_data.csv',
        singleClassification: SingleClassificationLabel(
          labeledAt: '2023-01-01T12:00:00Z',
          label: 'class1',
        ),
      );

      // Save the label entry
      await storageHelper.saveLabelEntries('test_project', [labelEntry]);

      // Load the label entry
      final loadedLabelEntries = await storageHelper.loadLabelEntries('test_project');

      expect(loadedLabelEntries.length, 1);
      expect(loadedLabelEntries[0].dataFilename, labelEntry.dataFilename);
      expect(loadedLabelEntries[0].singleClassification?.label, 'class1');
    });

    test('Download Project Config', () async {
      final project = Project(
        id: 'test_project',
        name: 'Test Project',
        mode: LabelingMode.singleClassification,
        classes: ['class1', 'class2'],
        dataPaths: [],
      );

      // Download the project config
      final filePath = await storageHelper.downloadProjectConfig(project);

      final file = File(filePath);
      expect(await file.exists(), true);

      final content = await file.readAsString();
      final loadedProject = Project.fromJson(jsonDecode(content));

      expect(loadedProject.id, project.id);
      expect(loadedProject.name, project.name);
    });

    test('Download Labels as ZIP', () async {
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

      // Download labels as ZIP
      final zipPath = await storageHelper.downloadLabelsAsZip(
        project,
        [labelEntry],
        [dataPath],
      );

      final zipFile = File(zipPath);
      expect(await zipFile.exists(), true);

      // Verify ZIP content (optional)
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      expect(archive.files.length, 2);
      expect(archive.files.any((file) => file.name == 'labels.json'), true);
      expect(archive.files.any((file) => file.name == 'test_data.csv'), true);
    });
  });
}
