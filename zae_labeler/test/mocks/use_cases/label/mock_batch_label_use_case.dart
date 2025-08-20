import 'package:zae_labeler/src/features/label/use_cases/batch_label_use_case.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';

class MockBatchLabelUseCase extends BatchLabelUseCase {
  List<LabelModel> mockLabels = [];
  Map<String, LabelModel> mockLabelMap = {};
  bool wasDeleteAllCalled = false;

  MockBatchLabelUseCase({required super.repository});

  List<LabelModel> get savedLabels => mockLabels;
  Map<String, LabelModel> get savedLabelMap => mockLabelMap;

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async => mockLabels;

  @override
  Future<Map<String, LabelModel>> loadLabelMap(String projectId) async => mockLabelMap;

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    mockLabels = labels;
  }

  @override
  Future<void> deleteAllLabels(String projectId) async {
    wasDeleteAllCalled = true;
    mockLabels.clear();
    mockLabelMap.clear();
  }
}
