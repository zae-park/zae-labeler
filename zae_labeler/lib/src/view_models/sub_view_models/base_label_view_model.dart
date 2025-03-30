// 📁 sub_view_models/base_label_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/project_model.dart';
import '../../models/label_model.dart';
import '../../models/sub_models/classification_label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';
import '../../services/storage_helper.dart';

abstract class LabelViewModel extends ChangeNotifier {
  final String projectId;
  final String dataId;
  final String dataFilename;
  final String dataPath;
  final LabelingMode mode;

  LabelModel labelModel;

  LabelViewModel({
    required this.projectId,
    required this.dataId,
    required this.dataFilename,
    required this.dataPath,
    required this.mode,
    required this.labelModel,
  });

  Future<void> loadLabel() async {
    labelModel = await StorageHelper.instance.loadLabelData(projectId, dataId, dataPath, mode);
    notifyListeners();
  }

  Future<void> saveLabel() async {
    await StorageHelper.instance.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  void updateLabel(dynamic labelData);
}
