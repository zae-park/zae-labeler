// lib/src/utils/storage_helper.dart
import '../models/data_model.dart';
import '../models/label_entry.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import 'proxy_storage_helper/interface_storage_helper.dart';
import 'proxy_storage_helper/native_storage_helper.dart' if (dart.library.html) 'proxy_storage_helper/web_storage_helper.dart';

class StorageHelper extends StorageHelperInterface {
  static final _instance = StorageHelperImpl();

  static StorageHelperInterface get instance => _instance;

  // Project IO
  @override
  Future<void> saveProjectConfig(List<Project> projects) => _instance.saveProjectConfig(projects);
  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) => _instance.loadProjectFromConfig(projectConfig);
  @override
  Future<String> downloadProjectConfig(Project project) => _instance.downloadProjectConfig(project);

  // Single LabelModel IO
  @override
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel) => _instance.saveLabelData(projectId, dataPath, labelModel);
  @override
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode) => _instance.loadLabelData(projectId, dataPath, mode);
  @override
  Future<String> downloadLabelData(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList);

  // Entire LabelModel IO
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels); // 프로젝트의 모든 Label 저장
  @override
  Future<List<LabelModel>> loadAllLabels(String projectId); // 프로젝트의 모든 Label 로드
  @override
  Future<List<LabelModel>> importAllLabels(); // 외부 Label 데이터 가져오기
}
