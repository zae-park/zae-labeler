import 'package:zae_labeler/src/features/label/use_cases/label_io_use_case.dart';
import 'package:zae_labeler/src/core/models/data/data_model.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

class MockLabelIOUseCase extends LabelIOUseCase {
  String exportPath = 'mock_export_path.json';
  List<LabelModel> importedLabels = [];

  MockLabelIOUseCase({required super.repository});

  List<LabelModel>? lastExportedLabels;
  Project? lastExportedProject;

  @override
  Future<String> exportLabels(Project project, List<LabelModel> labels) async {
    lastExportedProject = project;
    lastExportedLabels = labels;
    return exportPath;
  }

  @override
  Future<String> exportLabelsWithData(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) async => exportPath;

  @override
  Future<List<LabelModel>> importLabels() async => importedLabels;
}
