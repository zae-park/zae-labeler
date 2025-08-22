// lib/src/features/label/view_models/labeling_view_model.dart
import 'package:zae_labeler/src/core/models/label/label_model.dart' show LabelingMode;
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';

import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';

/// 각 라벨링 모드별 VM을 생성하는 빌더 시그니처
typedef VMBuilder = LabelingViewModel Function(Project project, StorageHelperInterface storage, AppUseCases appUseCases);

/// ✅ LabelingMode → VM 빌더 매핑
final Map<LabelingMode, VMBuilder> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, s, u) => ClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u),
  LabelingMode.multiClassification: (p, s, u) => ClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u),
  LabelingMode.crossClassification: (p, s, u) => CrossClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u),
  LabelingMode.singleClassSegmentation: (p, s, u) => SegmentationLabelingViewModel(project: p, storageHelper: s, appUseCases: u),
  LabelingMode.multiClassSegmentation: (p, s, u) => SegmentationLabelingViewModel(project: p, storageHelper: s, appUseCases: u),
};

/// ✅ LabelingViewModelFactory
/// - 프로젝트 모드에 맞는 VM 생성
class LabelingViewModelFactory {
  /// 동기 생성
  static LabelingViewModel create(Project project, StorageHelperInterface storage, AppUseCases useCases) {
    final builder = labelingViewModelBuilders[project.mode]!;
    return builder(project, storage, useCases);
  }

  /// 비동기 생성: VM 생성 + initialize()
  static Future<LabelingViewModel> createAsync(Project project, StorageHelperInterface storage, AppUseCases useCases) async {
    final vm = create(project, storage, useCases);
    await vm.initialize();
    return vm;
  }
}
