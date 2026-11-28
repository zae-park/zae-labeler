// lib/src/features/label/modes/labeling_mode_registry.dart
import 'package:flutter/widgets.dart';

import 'package:zae_labeler/src/core/models/label/label_model.dart' show LabelingMode;
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

import '../ui/pages/sub_pages/classification_labeling_page.dart';
import '../ui/pages/sub_pages/cross_classification_labeling_page.dart';
import '../ui/pages/sub_pages/segmentation_labeling_page.dart';
import '../use_cases/label_use_cases.dart';
import '../view_models/classification_labeling_view_model.dart';
import '../view_models/labeling_view_model.dart';
import '../view_models/segmentation_labeling_view_model.dart';

/// 라벨링 VM 생성에 필요한 의존성 묶음.
class LabelingDeps {
  final Project project;
  final StorageHelperInterface storageHelper;
  final LabelUseCases labelUseCases;

  const LabelingDeps({required this.project, required this.storageHelper, required this.labelUseCases});
}

/// 하나의 라벨링 모드가 "무엇으로 동작하고 어떻게 보이는지"를 정의합니다.
///
/// 새 모드를 추가할 때:
/// 1) `LabelingMode` enum 값 + LabelModel 서브클래스 + `LabelInputMapper` 구현
/// 2) VM과 페이지 구현
/// 3) 아래 [labelingModeSpecFor]에 한 줄 추가 (switch가 exhaustive라 누락 시 컴파일 에러)
class LabelingModeSpec<T extends LabelingViewModel> {
  final T Function(LabelingDeps deps) _create;
  final Widget Function(T vm) _page;

  const LabelingModeSpec({required T Function(LabelingDeps deps) create, required Widget Function(T vm) page}) : _create = create, _page = page;

  LabelingViewModel createViewModel(LabelingDeps deps) => _create(deps);

  /// [vm]은 반드시 이 spec의 [createViewModel]로 만든 인스턴스여야 합니다.
  Widget buildPage(LabelingViewModel vm) => _page(vm as T);
}

final _classification = LabelingModeSpec<ClassificationLabelingViewModel>(
  create: (d) => ClassificationLabelingViewModel(project: d.project, storageHelper: d.storageHelper, labelUseCases: d.labelUseCases),
  page: (vm) => ClassificationLabelingPage(viewModel: vm),
);

final _crossClassification = LabelingModeSpec<CrossClassificationLabelingViewModel>(
  create: (d) => CrossClassificationLabelingViewModel(project: d.project, storageHelper: d.storageHelper, labelUseCases: d.labelUseCases),
  page: (vm) => CrossClassificationLabelingPage(viewModel: vm),
);

final _segmentation = LabelingModeSpec<SegmentationLabelingViewModel>(
  create: (d) => SegmentationLabelingViewModel(project: d.project, storageHelper: d.storageHelper, labelUseCases: d.labelUseCases),
  page: (vm) => SegmentationLabelingPage(viewModel: vm),
);

/// 모드 → spec. 모든 모드 분기는 여기 한 곳에서만 일어납니다.
LabelingModeSpec labelingModeSpecFor(LabelingMode mode) => switch (mode) {
  LabelingMode.singleClassification || LabelingMode.multiClassification => _classification,
  LabelingMode.crossClassification => _crossClassification,
  LabelingMode.singleClassSegmentation || LabelingMode.multiClassSegmentation => _segmentation,
};
