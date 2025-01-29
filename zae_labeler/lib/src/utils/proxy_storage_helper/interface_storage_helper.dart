// lib/src/utils/platform_storage_helper.dart
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_entry.dart';

abstract class StorageHelperInterface {
  Future<String> downloadProjectConfig(Project project);
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
  Future<List<LabelEntry>> loadLabelEntries();
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries);
  Future<String> downloadLabelsAsZip(Project project, List<LabelEntry> labelEntries, List<DataPath> fileDataList);
  Future<List<LabelEntry>> importLabelEntries();
}
