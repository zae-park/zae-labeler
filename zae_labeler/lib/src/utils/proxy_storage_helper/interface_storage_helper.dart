// lib/src/utils/interface_storage_helper.dart
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';

abstract class StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================
  Future<void> saveProjectConfig(List<Project> projects);
  Future<List<Project>> loadProjectFromConfig(String projectConfig);
  Future<String> downloadProjectConfig(Project project);

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel);
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode);

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels);
  Future<List<LabelModel>> loadAllLabels(String projectId);

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList);
  Future<List<LabelModel>> importAllLabels();
}
