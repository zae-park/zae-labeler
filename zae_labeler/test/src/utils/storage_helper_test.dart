import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';

import '../../mocks/mock_storage_helper.dart';

void main() {
  late MockStorageHelper mockHelper;

  setUp(() {
    mockHelper = MockStorageHelper();
  });

  test('saveProjectConfig stores project list', () async {
    final project = Project(
      id: 'test-id',
      name: 'Test Project',
      mode: LabelingMode.singleClassification,
      classes: ['A', 'B'],
    );

    await mockHelper.saveProjectConfig([project]);

    expect(mockHelper.savedProjects.length, equals(1));
    expect(mockHelper.savedProjects.first.name, equals('Test Project'));
  });

  test('loadProjectFromConfig returns saved projects', () async {
    final project = Project(
      id: 'p2',
      name: 'Loadable Project',
      mode: LabelingMode.multiClassification,
      classes: ['C'],
    );

    await mockHelper.saveProjectConfig([project]);

    final loaded = await mockHelper.loadProjectFromConfig('irrelevant');

    expect(loaded.length, equals(1));
    expect(loaded.first.id, equals('p2'));
  });

  test('downloadProjectConfig returns mock path', () async {
    final project = Project(
      id: 'p3',
      name: 'Download Project',
      mode: LabelingMode.singleClassification,
      classes: ['X'],
    );

    final path = await mockHelper.downloadProjectConfig(project);

    expect(path, contains('Download Project_config.json'));
  });

  test('exportAllLabels returns mocked zip path', () async {
    final project = Project(
      id: 'p4',
      name: 'Export Project',
      mode: LabelingMode.singleClassification,
      classes: ['Y'],
    );

    final path = await mockHelper.exportAllLabels(project, [], []);

    expect(path, contains('Export Project_labels.zip'));
  });
}
