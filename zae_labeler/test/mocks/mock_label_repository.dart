import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/models/label_model.dart';
import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/repositories/label_repository.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

class MockLabelRepository implements LabelRepository {
  final Map<String, List<LabelModel>> _labelStore = {};
  bool wasSaveCalled = false;
  bool wasLoadCalled = false;
  bool wasExportCalled = false;
  bool wasImportCalled = false;
  bool wasDeleteCalled = false;

  @override
  final StorageHelperInterface storageHelper;

  MockLabelRepository({required this.storageHelper});

  @override
  Future<void> saveLabel({
    required String projectId,
    required String dataId,
    required String dataPath,
    required LabelModel labelModel,
  }) async {
    wasSaveCalled = true;
    _labelStore.putIfAbsent(projectId, () => []);
    _labelStore[projectId]!.removeWhere((l) => l.dataId == dataId);
    _labelStore[projectId]!.add(labelModel);
  }

  @override
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    wasLoadCalled = true;
    LabelModel? found = _labelStore[projectId]?.firstWhere((l) => l.dataId == dataId, orElse: () => LabelModelFactory.createNew(mode, dataId: dataId));
    found ??= LabelModelFactory.createNew(mode, dataId: dataId);
    return found;
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    wasSaveCalled = true;
    _labelStore[projectId] = labels;
  }

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    wasLoadCalled = true;
    return _labelStore[projectId] ?? [];
  }

  @override
  Future<void> deleteAllLabels(String projectId) async {
    wasDeleteCalled = true;
    _labelStore.remove(projectId);
  }

  @override
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    wasExportCalled = true;
    return '/mock/path/${project.name}_labels.json';
  }

  @override
  Future<List<LabelModel>> importLabels() async {
    wasImportCalled = true;
    return [];
  }

  @override
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) {
    // TODO: implement exportLabelsWithData
    throw UnimplementedError();
  }

  @override
  LabelStatus getStatus(Project project, LabelModel? labelModel) {
    // TODO: implement getStatus
    throw UnimplementedError();
  }

  @override
  bool isLabeled(LabelModel labelModel) {
    // TODO: implement isLabeled
    throw UnimplementedError();
  }

  @override
  bool isValid(Project project, LabelModel labelModel) {
    // TODO: implement isValid
    throw UnimplementedError();
  }

  @override
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) {
    // TODO: implement loadLabelMap
    throw UnimplementedError();
  }

  @override
  Future<LabelModel> loadOrCreateLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) {
    // TODO: implement loadOrCreateLabel
    throw UnimplementedError();
  }
}
