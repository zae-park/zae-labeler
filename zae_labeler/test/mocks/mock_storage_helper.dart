import 'dart:convert';
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';

class MockStorageHelper implements StorageHelperInterface {
  final Map<String, String> _mockDatabase = {}; // ✅ 인메모리 데이터 저장

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    if (_mockDatabase.containsKey('projects')) {
      final jsonData = jsonDecode(_mockDatabase['projects']!);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    _mockDatabase['projects'] = jsonEncode(projects.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel) async {
    final key = 'label_${projectId}_$dataPath';
    _mockDatabase[key] = jsonEncode({
      'mode': labelModel.runtimeType.toString(),
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': labelModel.labelData,
    });
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode) async {
    final key = 'label_${projectId}_$dataPath';
    if (_mockDatabase.containsKey(key)) {
      final jsonData = jsonDecode(_mockDatabase[key]!);
      return LabelModelConverter.fromJson(mode, jsonData['label_data']);
    }
    return LabelModelConverter.fromJson(mode, {});
  }

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async {
    return 'mock_export_path.zip';
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    return [];
  }

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    final labels = _mockDatabase.keys.where((key) => key.startsWith('label_$projectId')).toList();
    return labels.map((key) {
      final jsonData = jsonDecode(_mockDatabase[key]!);
      final mode = LabelingMode.values.firstWhere((e) => e.toString() == jsonData['mode']);
      return LabelModelConverter.fromJson(mode, jsonData['label_data']);
    }).toList();
  }

  @override
  Future<String> downloadProjectConfig(Project project) {
    // TODO: implement downloadProjectConfig
    throw UnimplementedError();
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) {
    // TODO: implement saveAllLabels
    throw UnimplementedError();
  }
}
