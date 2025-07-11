import 'package:zae_labeler/src/features/label/use_cases/single_label_use_case.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';

class MockSingleLabelUseCase extends SingleLabelUseCase {
  final Map<String, LabelModel> _labelMap = {};

  MockSingleLabelUseCase({required super.repository});

  @override
  Future<LabelModel> loadLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    return _labelMap[dataId] ?? LabelModelFactory.createNew(mode, dataId: dataId);
  }

  @override
  Future<void> saveLabel({required String projectId, required String dataId, required String dataPath, required LabelModel labelModel}) async {
    _labelMap[dataId] = labelModel;
  }

  @override
  Future<LabelModel> loadOrCreateLabel({required String projectId, required String dataId, required String dataPath, required LabelingMode mode}) async {
    return _labelMap[dataId] ??= LabelModelFactory.createNew(mode, dataId: dataId);
  }

  @override
  bool isLabeled(LabelModel labelModel) {
    return labelModel.isLabeled;
  }
}
