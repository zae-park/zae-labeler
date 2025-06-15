// 📁 sub_view_models/base_label_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/label_model.dart';
import '../../domain/label/label_use_cases.dart';
import '../managers/label_input_mapper.dart';

abstract class LabelViewModel extends ChangeNotifier {
  final String projectId;
  final LabelUseCases labelUseCases;

  String dataId;
  String dataFilename;
  String dataPath;
  LabelingMode mode;
  LabelModel labelModel;
  LabelInputMapper labelInputMapper;

  LabelViewModel({
    required this.projectId,
    required this.dataId,
    required this.dataFilename,
    required this.dataPath,
    required this.mode,
    required this.labelModel,
    required this.labelUseCases,
    required this.labelInputMapper,
  });

  Future<void> loadLabel() async {
    debugPrint("[BaseLabelVM.loadLabel] BEFORE: ${labelModel.runtimeType}");
    labelModel = await labelUseCases.single.loadLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    debugPrint("[BaseLabelVM.loadLabel] AFTER: ${labelModel.runtimeType}");
    notifyListeners();
  }

  Future<void> saveLabel() async {
    debugPrint("[BaseLabelVM.saveLabel] labelModel: $labelModel");
    debugPrint("[BaseLabelVM.saveLabel] saving label: ${labelModel.label}");
    await labelUseCases.single.saveLabel(projectId: projectId, dataId: dataId, dataPath: dataPath, labelModel: labelModel);
  }

  Future<void> updateLabel(LabelModel newModel) async {
    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  Future<void> updateLabelFromInput(dynamic labelData) async {
    final newModel = labelInputMapper.map(labelData, dataId: dataId, dataPath: dataPath);
    await updateLabel(newModel);
  }

  bool isLabelSelected(String labelItem) => throw UnimplementedError("Only for classification");
  void toggleLabel(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> addPixel(int x, int y, String classLabel) => throw UnimplementedError("Only for segmentation");
  Future<void> removePixel(int x, int y) => throw UnimplementedError("Only for segmentation");
}
