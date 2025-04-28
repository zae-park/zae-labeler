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

/// ✅ 라벨링 모드에 따라 적절한 ViewModel을 생성해주는 팩토리
class LabelingViewModelFactory {
  static LabelingViewModel create(Project project, StorageHelperInterface helper) {
    switch (project.mode) {
      case LabelingMode.singleClassification:
      case LabelingMode.multiClassification:
        return ClassificationLabelingViewModel(project: project, storageHelper: helper);
      case LabelingMode.crossClassification:
        return CrossClassificationLabelingViewModel(project: project, storageHelper: helper);
      case LabelingMode.singleClassSegmentation:
      case LabelingMode.multiClassSegmentation:
        return SegmentationLabelingViewModel(project: project, storageHelper: helper);
    }
  }
}
