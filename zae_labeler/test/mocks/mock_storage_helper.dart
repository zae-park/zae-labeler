import 'dart:convert';
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_entry.dart';
import 'package:zae_labeler/src/models/data_model.dart';

class MockStorageHelper implements StorageHelperInterface {
  final Map<String, String> _mockDatabase = {}; // ✅ 인메모리 데이터 저장

  @override
  Future<List<Project>> loadProjects() async {
    if (_mockDatabase.containsKey('projects')) {
      final jsonData = jsonDecode(_mockDatabase['projects']!);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    _mockDatabase['projects'] = jsonEncode(projects.map((e) => e.toJson()).toList());
  }

  @override
  Future<List<LabelEntry>> loadLabelEntries(String projectId) async {
    if (_mockDatabase.containsKey('labels')) {
      final jsonData = jsonDecode(_mockDatabase['labels']!);
      return (jsonData as List).map((e) => LabelEntry.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> saveLabelEntries(String projectId, List<LabelEntry> labelEntries) async {
    _mockDatabase['labels'] = jsonEncode(labelEntries.map((e) => e.toJson()).toList());
  }

  @override
  Future<void> saveLabelEntry(String projectId, LabelEntry labelEntry) async {
    List<LabelEntry> existingEntries = await loadLabelEntries(projectId);
    int index = existingEntries.indexWhere((entry) => entry.dataFilename == labelEntry.dataFilename);
    if (index != -1) {
      existingEntries[index] = labelEntry;
    } else {
      existingEntries.add(labelEntry);
    }
    _mockDatabase['labels'] = jsonEncode(existingEntries.map((e) => e.toJson()).toList());
  }

  @override
  Future<LabelEntry> loadLabelEntry(String projectId, String dataPath) async {
    List<LabelEntry> existingEntries = await loadLabelEntries(projectId);
    return existingEntries.firstWhere(
      (entry) => entry.dataPath == dataPath,
      orElse: () => LabelEntry.empty(), // ✅ null 대신 기본값 반환
    );
  }

  @override
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<DataPath> fileDataList) async {
    return 'mock_zip_path.zip';
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    return 'mock_project_config.json';
  }

  @override
  Future<List<LabelEntry>> importLabelEntries() async {
    return [];
  }
}
