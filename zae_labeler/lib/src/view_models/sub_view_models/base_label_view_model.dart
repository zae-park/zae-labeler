// 📁 sub_view_models/base_label_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/label_model.dart';
import '../../utils/storage_helper.dart';

abstract class LabelViewModel extends ChangeNotifier {
  final String projectId;
  final String dataId;
  final String dataFilename;
  final String dataPath;
  final LabelingMode mode;
  final StorageHelperInterface storageHelper;

  LabelModel labelModel;

  LabelViewModel({
    required this.projectId,
    required this.dataId,
    required this.dataFilename,
    required this.dataPath,
    required this.mode,
    required this.labelModel,
    required this.storageHelper,
  });

  Future<void> loadLabel() async {
    debugPrint("[BaseLabelVM.loadLabel] BEFORE: ${labelModel.runtimeType}");
    labelModel = await storageHelper.loadLabelData(projectId, dataId, dataPath, mode);
    debugPrint("[BaseLabelVM.loadLabel] AFTER: ${labelModel.runtimeType}");
    notifyListeners();
  }

  Future<void> saveLabel() async {
    debugPrint("[BaseLabelVM.saveLabel] labelModel: $labelModel");
    debugPrint("[BaseLabelVM.saveLabel] saving label: ${labelModel.label}");
    await storageHelper.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  void updateLabel(dynamic labelData);
}
