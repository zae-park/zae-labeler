// test/mocks/repositories/mock_label_repository.dart
import 'package:zae_labeler/src/core/models/project_model.dart';
import 'package:zae_labeler/src/core/models/label_model.dart';
import 'package:zae_labeler/src/core/models/data_model.dart';
import 'package:zae_labeler/src/features/label/repository/label_repository.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';

import '../helpers/mock_storage_helper.dart';

class MockLabelRepository extends LabelRepository {
  final Map<String, Map<String, LabelModel>> _labelStore = {}; // projectId -> (dataId -> label)
  List<LabelModel> lastSaved = [];

  MockLabelRepository() : super(storageHelper: MockStorageHelper());

  @override
  Future<void> saveLabel({required String projectId, required String dataId, required String dataPath, required LabelModel labelModel}) async {
    _labelStore.putIfAbsent(projectId, () => {})[dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    return _labelStore[projectId]?[dataId] ?? LabelModelFactory.createNew(mode, dataId: dataId);
  }

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async => _labelStore[projectId]?.values.toList() ?? [];

  @override
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) async {
    final labels = await loadAllLabels(projectId);
    return {for (var l in labels) l.dataId: l};
  }

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    _labelStore[projectId] = {for (var l in labels) l.dataId: l};
    lastSaved = labels;
  }

  @override
  Future<void> deleteAllLabels(String projectId) async {
    _labelStore.remove(projectId);
  }

  @override
  Future<String> exportLabels(Project project, List<LabelModel> labels) async => '/mock/export/${project.id}_labels.json';

  @override
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) async => '/mock/export/${project.id}_full.json';

  @override
  Future<List<LabelModel>> importLabels() async => _labelStore.values.expand((map) => map.values).toList();

  @override
  bool isValid(Project project, LabelModel labelModel) => LabelValidator.isValid(labelModel, project);

  @override
  LabelStatus getStatus(Project project, LabelModel? labelModel) => LabelValidator.getStatus(project, labelModel);

  @override
  bool isLabeled(LabelModel labelModel) => labelModel.isLabeled;
}
