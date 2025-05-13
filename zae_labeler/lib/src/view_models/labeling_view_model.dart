// lib/view_models/labeling_view_model.dart
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';
import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';
export 'sub_view_models/base_labeling_view_model.dart';
export 'sub_view_models/classification_labeling_view_model.dart';
export 'sub_view_models/segmentation_labeling_view_model.dart';

final Map<LabelingMode, LabelingViewModel Function(Project, StorageHelperInterface)> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, h) => ClassificationLabelingViewModel(project: p, storageHelper: h),
  LabelingMode.multiClassification: (p, h) => ClassificationLabelingViewModel(project: p, storageHelper: h),
  LabelingMode.crossClassification: (p, h) => CrossClassificationLabelingViewModel(project: p, storageHelper: h),
  LabelingMode.singleClassSegmentation: (p, h) => SegmentationLabelingViewModel(project: p, storageHelper: h),
  LabelingMode.multiClassSegmentation: (p, h) => SegmentationLabelingViewModel(project: p, storageHelper: h),
};

class LabelingViewModelFactory {
  static LabelingViewModel create(Project project, StorageHelperInterface helper) {
    return labelingViewModelBuilders[project.mode]!(project, helper);
  }
}
