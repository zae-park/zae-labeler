import 'package:zae_labeler/src/features/label/use_cases/batch_label_use_case.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/label/use_cases/labeling_summary_use_case.dart';

class MockLabelSummaryUseCase extends LabelingSummaryUseCase {
  MockLabelSummaryUseCase({required super.repository, required super.validUseCase});

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
