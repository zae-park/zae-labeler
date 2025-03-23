import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/sub_models/classification_label_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';

class MockStorageHelper implements StorageHelperInterface {
  List<Project> savedProjects = [];

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    savedProjects = projects;
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String config) async {
    return savedProjects;
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    return '/mock/path/${project.name}_config.json';
  }

  @override
  Future<void> saveProjectList(List<Project> projects) async {}

  @override
  Future<List<Project>> loadProjectList() async => [];

  @override
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel) async {}

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode) async => SingleClassificationLabelModel.empty();

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {}

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async => [];

  @override
  Future<void> deleteProjectLabels(String projectId) async {}

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async => '/mock/path/${project.name}_labels.zip';

  @override
  Future<List<LabelModel>> importAllLabels() async => [];

  @override
  Future<void> clearAllCache() async {}
}

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
