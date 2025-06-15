import '../../lib/src/domain/label/label_use_cases.dart';
import '../../lib/src/models/label_model.dart';
import '../../lib/src/models/project_model.dart';

class MockLabelUseCases extends LabelUseCases {
  final List<LabelModel> savedLabels = [];

  @override
  final mockRepository = MockLabelRepository();

  @override
  final validation = MockLabelValidator();

  @override
  final batch = MockLabelBatchIO();

  @override
  final io = MockLabelIO();

  @override
  Future<void> saveLabel(String projectId, LabelModel label) async {
    savedLabels.add(label);
  }

  @override
  Future<LabelModel?> loadLabel(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    return null;
  }
}

class MockLabelRepository {
  Future<void> deleteAllLabels(String projectId) async {}
}

class MockLabelValidator {
  LabelStatus getStatus(Project project, LabelModel label) => LabelStatus.incomplete;
}

class MockLabelBatchIO {
  Future<List<LabelModel>> loadAllLabels(String projectId) async => [];
}

class MockLabelIO {
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<dynamic> dataInfos) async => '{}';
}
