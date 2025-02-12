// lib/src/utils/interface_storage_helper.dart
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_entry.dart';

abstract class StorageHelperInterface {
  Future<void> saveProjects(List<Project> projects);
  Future<List<Project>> loadProjects();
  Future<String> downloadProjectConfig(Project project);

  Future<void> saveLabelEntries(String projectId, List<LabelEntry> labelEntries);
  Future<List<LabelEntry>> loadLabelEntries(String projectId);
  Future<List<LabelEntry>> importLabelEntries();
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<DataPath> fileDataList);

  Future<void> saveLabelEntry(String projectId, LabelEntry newEntry);
  Future<LabelEntry> loadLabelEntry(String projectId, String dataPath);
}
