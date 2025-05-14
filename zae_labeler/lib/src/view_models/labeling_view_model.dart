// lib/view_models/labeling_view_model.dart
import '../models/data_model.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';
import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';
export 'sub_view_models/base_labeling_view_model.dart';
export 'sub_view_models/classification_labeling_view_model.dart';
export 'sub_view_models/segmentation_labeling_view_model.dart';

final Map<LabelingMode, LabelingViewModel Function(Project, StorageHelperInterface, List<UnifiedData>?)> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, h, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, initialDataList: dl),
  LabelingMode.multiClassification: (p, h, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, initialDataList: dl),
  LabelingMode.crossClassification: (p, h, dl) => CrossClassificationLabelingViewModel(project: p, storageHelper: h, initialDataList: dl),
  LabelingMode.singleClassSegmentation: (p, h, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, initialDataList: dl),
  LabelingMode.multiClassSegmentation: (p, h, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, initialDataList: dl),
};

class LabelingViewModelFactory {
  static LabelingViewModel create(Project project, StorageHelperInterface helper, {List<UnifiedData>? initialDataList}) {
    return labelingViewModelBuilders[project.mode]!(project, helper, initialDataList);
  }
}
