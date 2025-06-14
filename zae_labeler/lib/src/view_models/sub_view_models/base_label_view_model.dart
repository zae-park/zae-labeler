// 📁 sub_view_models/base_label_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/label_model.dart';
import '../../domain/label/label_use_cases.dart';

abstract class LabelViewModel extends ChangeNotifier {
  final String projectId;
  final String dataId;
  final String dataFilename;
  final String dataPath;
  final LabelingMode mode;
  final LabelUseCases labelUseCases;

  LabelModel labelModel;

  LabelViewModel({
    required this.projectId,
    required this.dataId,
    required this.dataFilename,
    required this.dataPath,
    required this.mode,
    required this.labelModel,
    required this.labelUseCases,
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

  void updateLabel(dynamic labelData);
  bool isLabelSelected(String labelItem) => throw UnimplementedError("Only for classification");
  void toggleLabel(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> addPixel(int x, int y, String classLabel) => throw UnimplementedError("Only for segmentation");
  Future<void> removePixel(int x, int y) => throw UnimplementedError("Only for segmentation");
}
