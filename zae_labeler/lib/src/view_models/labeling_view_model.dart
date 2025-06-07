import '../models/data_model.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/adaptive/adaptive_data_loader.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../repositories/label_repository.dart';

import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';

export 'sub_view_models/base_labeling_view_model.dart';
export 'sub_view_models/classification_labeling_view_model.dart';
export 'sub_view_models/segmentation_labeling_view_model.dart';

/// ✅ LabelingMode에 따른 ViewModel 빌더 매핑
final Map<LabelingMode, LabelingViewModel Function(Project, StorageHelperInterface, LabelRepository, List<UnifiedData>?)> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, h, r, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, labelRepository: r, initialDataList: dl),
  LabelingMode.multiClassification: (p, h, r, dl) => ClassificationLabelingViewModel(project: p, storageHelper: h, labelRepository: r, initialDataList: dl),
  LabelingMode.crossClassification: (p, h, r, dl) =>
      CrossClassificationLabelingViewModel(project: p, storageHelper: h, labelRepository: r, initialDataList: dl),
  LabelingMode.singleClassSegmentation: (p, h, r, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, labelRepository: r, initialDataList: dl),
  LabelingMode.multiClassSegmentation: (p, h, r, dl) => SegmentationLabelingViewModel(project: p, storageHelper: h, labelRepository: r, initialDataList: dl),
};

/// ✅ LabelingViewModelFactory
/// - 프로젝트 모드에 따라 적절한 LabelingViewModel을 생성
class LabelingViewModelFactory {
  /// 동기 생성자
  static LabelingViewModel create(Project project, StorageHelperInterface helper, LabelRepository labelRepository, {List<UnifiedData>? initialDataList}) {
    return labelingViewModelBuilders[project.mode]!(project, helper, labelRepository, initialDataList);
  }

  /// 비동기 생성자
  /// - 플랫폼에 따라 데이터를 로딩하고 초기화까지 수행한 ViewModel 반환
  static Future<LabelingViewModel> createAsync(Project project, StorageHelperInterface helper, LabelRepository labelRepository) async {
    final data = await loadDataAdaptively(project, helper);
    final vm = labelingViewModelBuilders[project.mode]!(project, helper, labelRepository, data);
    await vm.initialize();
    return vm;
  }
}
