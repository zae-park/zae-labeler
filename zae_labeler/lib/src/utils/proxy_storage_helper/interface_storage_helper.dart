import '../../models/project_model.dart';
import '../../models/label_entry.dart';

abstract class PlatformStorageHelper {
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
  Future<List<LabelEntry>> loadLabelEntries();
  Future<void> saveLabelEntries(List<LabelEntry> labelEntries);
  Future<String> downloadLabelsAsZip(
      Project project, List<LabelEntry> labelEntries, List<dynamic> dataFiles);
}
