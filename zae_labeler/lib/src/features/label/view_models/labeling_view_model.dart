import '../../../core/models/data/data_model.dart';
import '../models/label_model.dart';
import '../../../core/models/project/project_model.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';
import '../../../core/use_cases/app_use_cases.dart';
import '../../../core/services/adaptive_data_loader.dart';

import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';

export 'sub_view_models/base_labeling_view_model.dart';
export 'sub_view_models/classification_labeling_view_model.dart';
export 'sub_view_models/segmentation_labeling_view_model.dart';

/// ✅ LabelingMode에 따른 ViewModel 빌더 매핑
final Map<LabelingMode, LabelingViewModel Function(Project, StorageHelperInterface, AppUseCases, List<UnifiedData>?)> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, h, u, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, appUseCases: u, initialDataList: dl),
  LabelingMode.multiClassification: (p, h, u, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, appUseCases: u, initialDataList: dl),
  LabelingMode.crossClassification: (p, h, u, dl) => CrossClassificationLabelingViewModel(project: p, storageHelper: h, appUseCases: u, initialDataList: dl),
  LabelingMode.singleClassSegmentation: (p, h, u, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, appUseCases: u, initialDataList: dl),
  LabelingMode.multiClassSegmentation: (p, h, u, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, appUseCases: u, initialDataList: dl),
};

/// ✅ LabelingViewModelFactory
/// - 프로젝트 모드에 따라 적절한 LabelingViewModel을 생성
class LabelingViewModelFactory {
  /// 동기 생성자
  static LabelingViewModel create(Project project, StorageHelperInterface helper, AppUseCases useCases, {List<UnifiedData>? initialDataList}) {
    return labelingViewModelBuilders[project.mode]!(project, helper, useCases, initialDataList);
  }

  /// 비동기 생성자
  /// - 플랫폼에 따라 데이터를 로딩하고 초기화까지 수행한 ViewModel 반환
  static Future<LabelingViewModel> createAsync(Project project, StorageHelperInterface helper, AppUseCases useCases) async {
    final data = await loadDataAdaptively(project, helper);
    final vm = labelingViewModelBuilders[project.mode]!(project, helper, useCases, data);
    await vm.initialize();
    return vm;
  }
}
