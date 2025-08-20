// lib/src/features/label/view_models/labeling_view_model.dart
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart' show loadDataAdaptively;

import '../models/label_model.dart' show LabelingMode;
import '../../../core/models/project/project_model.dart';
import '../../../platform_helpers/storage/interface_storage_helper.dart';
import '../../../core/use_cases/app_use_cases.dart';

import 'sub_view_models/base_labeling_view_model.dart';
import 'sub_view_models/classification_labeling_view_model.dart';
import 'sub_view_models/segmentation_labeling_view_model.dart';

typedef VMBuilder = LabelingViewModel Function(Project project, StorageHelperInterface storage, AppUseCases appUseCases, List<UnifiedData>? initialData);

/// ✅ LabelingMode → VM 빌더 매핑 (initialData: List<UnifiedData>?)
final Map<LabelingMode, VMBuilder> labelingViewModelBuilders = {
  LabelingMode.singleClassification: (p, s, u, d) => ClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u, initialDataList: d),
  LabelingMode.multiClassification: (p, s, u, d) => ClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u, initialDataList: d),
  LabelingMode.crossClassification: (p, s, u, d) => CrossClassificationLabelingViewModel(project: p, storageHelper: s, appUseCases: u, initialDataList: d),
  LabelingMode.singleClassSegmentation: (p, s, u, d) => SegmentationLabelingViewModel(project: p, storageHelper: s, appUseCases: u, initialDataList: d),
  LabelingMode.multiClassSegmentation: (p, s, u, d) => SegmentationLabelingViewModel(project: p, storageHelper: s, appUseCases: u, initialDataList: d),
};

/// ✅ LabelingViewModelFactory
/// - 프로젝트 모드에 맞는 VM 생성
class LabelingViewModelFactory {
  /// 동기 생성
  static LabelingViewModel create(Project project, StorageHelperInterface storage, AppUseCases useCases, {List<UnifiedData>? initialData}) {
    final builder = labelingViewModelBuilders[project.mode]!;
    return builder(project, storage, useCases, initialData);
  }

  /// 비동기 생성: 데이터 로드 + VM 초기화
  static Future<LabelingViewModel> createAsync(Project project, StorageHelperInterface storage, AppUseCases useCases) async {
    final data = await loadDataAdaptively(project, storage); // List<UnifiedData>
    final vm = create(project, storage, useCases, initialData: data);
    await vm.initialize();
    return vm;
  }
}
