// test/support/in_memory_storage_helper.dart
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

/// 프로젝트 목록과 라벨 저장/조회를 메모리로 구현한 테스트용 스토리지.
/// 호출 횟수를 기록해 "저장 1회", "일괄 로드 1회" 같은 계약을 검증할 수 있습니다.
class InMemoryStorageHelper implements StorageHelperInterface {
  final Map<String, Map<String, LabelModel>> _labels = {};
  List<Project> projects = [];

  int saveProjectListCalls = 0;
  int loadProjectListCalls = 0;

  int saveLabelCalls = 0;
  int loadAllCalls = 0;
  int loadSingleCalls = 0;
  final List<String> revokedUrls = [];

  /// 초기 라벨을 심어 둡니다(호출 횟수에 포함되지 않음).
  void seed(String projectId, List<LabelModel> labels) {
    final map = _labels.putIfAbsent(projectId, () => {});
    for (final l in labels) {
      map[l.dataId] = l;
    }
  }

  LabelModel? stored(String projectId, String dataId) => _labels[projectId]?[dataId];

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) async {
    saveLabelCalls++;
    _labels.putIfAbsent(projectId, () => {})[dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    loadSingleCalls++;
    return _labels[projectId]?[dataId] ?? LabelModelFactory.createNew(mode, dataId: dataId);
  }

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) async {
    loadAllCalls++;
    return List<LabelModel>.from(_labels[projectId]?.values ?? const <LabelModel>[]);
  }

  @override
  Future<List<Project>> loadProjectList() async {
    loadProjectListCalls++;
    return List<Project>.from(projects);
  }

  @override
  Future<void> saveProjectList(List<Project> list) async {
    saveProjectListCalls++;
    projects = List<Project>.from(list);
  }

  int saveProjectCalls = 0;

  @override
  Future<void> saveProject(Project project) async {
    saveProjectCalls++;
    final i = projects.indexWhere((p) => p.id == project.id);
    i < 0 ? projects.add(project) : projects[i] = project;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    projects = projects.where((p) => p.id != projectId).toList();
    _labels.remove(projectId);
  }

  @override
  Future<void> deleteProjectLabels(String projectId) async => _labels.remove(projectId);

  @override
  Future<String> downloadProjectConfig(Project project) async => 'config://${project.id}';

  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) async => null;

  @override
  Future<void> revokeLocalObjectUrl(String url) async => revokedUrls.add(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
