import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';
import 'package:zae_labeler/src/repositories/label_repository.dart';

import 'mock_storage_helper.dart';

/// 🧪 테스트용 MockLabelRepository
class MockLabelRepository extends LabelRepository {
  final Map<String, Map<String, LabelModel>> _labelStorage = {}; // [projectId][dataId]
  final Map<String, List<LabelModel>> _importedLabels = {};
  List<LabelModel> lastSavedLabels = [];
  bool shouldThrowOnSave = false;
  bool shouldThrowOnLoad = false;

  MockLabelRepository({StorageHelperInterface? storageHelper}) : super(storageHelper: storageHelper ?? MockStorageHelper());

  @override
  Future<void> saveLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelModel labelModel,
  }) async {
    if (shouldThrowOnSave) throw Exception('Save failed');
    _labelStorage.putIfAbsent(projectId, () => {})[dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelingMode mode,
  }) async {
    if (shouldThrowOnLoad) throw Exception('Load failed');
    return _labelStorage[projectId]?[dataId] ?? LabelModelFactory.createNew(mode, dataId: dataId);
  }

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    return _labelStorage[projectId]?.values.toList() ?? [];
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final map = {for (var l in labels) l.dataId: l};
    _labelStorage[projectId] = map;
    lastSavedLabels = labels;
  }

  @override
  Future<void> deleteAllLabels(String projectId) async {
    _labelStorage.remove(projectId);
  }

  @override
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    return '/mock/export/path/${project.id}_labels.zip';
  }

  @override
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) async {
    return '/mock/export/path/${project.id}_with_data.zip';
  }

  @override
  Future<List<LabelModel>> importLabels() async {
    return _importedLabels.values.expand((x) => x).toList();
  }

  @override
  bool isValid(Project project, LabelModel labelModel) {
    return true; // 테스트에서는 항상 valid로 처리
  }

  @override
  LabelStatus getStatus(Project project, LabelModel? labelModel) {
    return labelModel == null ? LabelStatus.incomplete : LabelStatus.complete;
  }

  @override
  bool isLabeled(LabelModel labelModel) {
    return labelModel.isLabeled;
  }
}
