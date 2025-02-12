// lib/src/utils/storage_helper.dart
import '../models/data_model.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import 'proxy_storage_helper/interface_storage_helper.dart';
import 'proxy_storage_helper/native_storage_helper.dart' if (dart.library.html) 'proxy_storage_helper/web_storage_helper.dart';

class StorageHelper extends StorageHelperInterface {
  static final _instance = StorageHelperImpl();

  static StorageHelperInterface get instance => _instance;

  // Project IO
  @override
  Future<void> saveProjects(List<Project> projects) => _instance.saveProjects(projects);
  @override
  Future<List<Project>> loadProjects() => _instance.loadProjects();
  @override
  Future<String> downloadProjectConfig(Project project) => _instance.downloadProjectConfig(project);

  // LabelEntries IO
  @override
  Future<void> saveLabelEntries(String projectId, List<LabelEntry> labelEntries) => _instance.saveLabelEntries(projectId, labelEntries);
  @override
  Future<List<LabelEntry>> loadLabelEntries(String projectId) => _instance.loadLabelEntries(projectId);
  @override
  Future<List<LabelEntry>> importLabelEntries() => _instance.importLabelEntries();
  @override
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<DataPath> fileDataList) =>
      _instance.downloadLabelsAsZip(project, labelEntries, fileDataList);

  // LabelEntry IO
  @override
  Future<void> saveLabelEntry(String projectId, LabelEntry newEntry) => _instance.saveLabelEntry(projectId, newEntry);
  @override
  Future<LabelEntry> loadLabelEntry(String projectId, String dataPath) => _instance.loadLabelEntry(projectId, dataPath);
}
