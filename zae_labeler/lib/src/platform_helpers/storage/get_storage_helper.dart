// lib/src/utils/storage_helper.dart
import '../../core/models/data_model.dart';
import '../../core/models/label_model.dart';
import '../../core/models/project_model.dart';
import 'interface_storage_helper.dart';
import 'stub_storage_helper.dart'
    if (dart.library.io) 'proxy_storage_helper/native_storage_helper.dart'
    if (dart.library.html) 'proxy_storage_helper/web_storage_helper.dart';
export 'interface_storage_helper.dart';

/// ✅ **StorageHelper: 플랫폼별 StorageHelperImpl을 Wrapping하는 클래스**
/// - Web과 Native 환경에 따라 `StorageHelperImpl`이 자동으로 선택됨.
/// - 프로젝트 및 Label 데이터를 저장/로드/다운로드하는 기능을 제공.
///
/// 📌 **저장 위치**
/// - **Web:** `localStorage` 또는 브라우저 다운로드 (ZIP 파일)
/// - **Native:** `Application Documents Directory` 내 JSON 파일 저장
class StorageHelper extends StorageHelperInterface {
  static final StorageHelperInterface _instance = StorageHelperImpl();

  /// ✅ **StorageHelper 인스턴스 반환**
  /// - 플랫폼에 따라 적절한 `StorageHelperImpl`을 반환
  static StorageHelperInterface get instance => _instance;

  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================

  /// ✅ **프로젝트 설정 저장**
  /// - Web: `localStorage`
  /// - Native: `projects.json` 파일 저장
  @override
  Future<void> saveProjectConfig(List<Project> projects) => _instance.saveProjectConfig(projects);

  /// ✅ **저장된 프로젝트 설정 불러오기**
  /// - Web: `localStorage`에서 JSON 로드
  /// - Native: `projects.json` 파일 로드
  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) => _instance.loadProjectFromConfig(projectConfig);

  /// ✅ **프로젝트 설정을 JSON 파일로 다운로드**
  /// - Web: 브라우저에서 JSON 파일 자동 다운로드
  /// - Native: 파일 시스템 (`<project_name>_config.json`)에 저장 후 경로 반환
  @override
  Future<String> downloadProjectConfig(Project project) => _instance.downloadProjectConfig(project);

  // ==============================
  // 📌 **Project List Management**
  // ==============================

  /// ✅ **프로젝트 리스트 저장**
  /// - Web: `localStorage['projects']`
  /// - Native: `projects.json` 파일 저장
  @override
  Future<void> saveProjectList(List<Project> projects) => _instance.saveProjectList(projects);

  /// ✅ **저장된 프로젝트 리스트 불러오기**
  /// - Web: `localStorage`에서 JSON 읽기
  /// - Native: `projects.json` 파일에서 JSON 읽기
  @override
  Future<List<Project>> loadProjectList() => _instance.loadProjectList();

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================

  /// ✅ **개별 데이터(Label) 저장**
  /// - Web: `localStorage['labels_project_<projectId>']`
  /// - Native: `labels_project_<projectId>.json` 파일 저장
  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) =>
      _instance.saveLabelData(projectId, dataId, dataPath, labelModel);

  /// ✅ **개별 데이터(Label) 불러오기**
  /// - Web: `localStorage`에서 JSON 읽기
  /// - Native: `labels_project_<projectId>.json` 파일에서 JSON 읽기
  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) =>
      _instance.loadLabelData(projectId, dataId, dataPath, mode);

  /// ✅ **프로젝트 내 Label 삭제**
  /// - Web: `localStorage`에서 JSON 삭제
  /// - Native: `labels_project_<projectId>.json` 파일에서 JSON 삭제
  @override
  Future<void> deleteProjectLabels(String projectId) => _instance.deleteProjectLabels(projectId);

  @override
  Future<void> deleteProject(String projectId) => _instance.deleteProject(projectId);

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================

  /// ✅ **프로젝트 내 모든 Label 저장**
  /// - Web: `localStorage['labels_project_<projectId>']`
  /// - Native: `labels_project_<projectId>.json` 파일 저장
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) => _instance.saveAllLabels(projectId, labels);

  /// ✅ **프로젝트 내 모든 Label 불러오기**
  /// - Web: `localStorage`에서 JSON 읽기
  /// - Native: `labels_project_<projectId>.json` 파일에서 JSON 읽기
  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) => _instance.loadAllLabelModels(projectId);

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================

  /// ✅ **Label 데이터를 ZIP 파일로 다운로드**
  /// - Web: `Blob()`을 활용한 자동 다운로드 (`labels_project_<projectId>.zip`)
  /// - Native: `labels_project_<projectId>.zip` 파일을 생성 후 경로 반환
  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataInfo> fileDataList) =>
      _instance.exportAllLabels(project, labelModels, fileDataList);

  /// ✅ **외부 Label JSON 데이터를 가져오기**
  /// - Web: `FileReader()`를 사용하여 JSON 파일 로드
  /// - Native: `labels_import.json` 파일에서 JSON 데이터 읽기
  @override
  Future<List<LabelModel>> importAllLabels() => _instance.importAllLabels();

  // ==============================
  // 📌 **Cache Management**
  // ==============================

  /// ✅ **모든 캐시 삭제 (Web: localStorage 초기화, Native: 프로젝트 데이터 삭제)**
  @override
  Future<void> clearAllCache() => _instance.clearAllCache();
}
