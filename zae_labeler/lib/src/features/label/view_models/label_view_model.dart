// lib/src/features/label/view_models/label_view_model.dart

import 'package:flutter/foundation.dart';

import '../../../core/models/project/project_model.dart';
import '../../../core/models/data/unified_data.dart';

import '../../../core/models/label/label_model.dart';
import '../logic/label_input_mapper.dart';
import '../use_cases/label_use_cases.dart';

// 서브 VM들
import 'sub_view_models/base_label_view_model.dart';
import 'sub_view_models/classification_label_view_model.dart';
import 'sub_view_models/segmentation_label_view_model.dart';

export 'sub_view_models/base_label_view_model.dart';
export 'sub_view_models/classification_label_view_model.dart';
export 'sub_view_models/segmentation_label_view_model.dart';

/// ✅ LabelViewModelFactory
/// - 프로젝트/데이터 컨텍스트로 적합한 서브 VM을 생성.
/// - 초기 라벨/매퍼가 필요하면 optional 인자로 오버라이드 가능.
class LabelViewModelFactory {
  static LabelViewModel create(
      {required Project project, required UnifiedData data, required LabelUseCases labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper}) {
    final mode = project.mode;
    final resolvedMapper = mapper ?? LabelInputMapper.forMode(mode);
    final resolvedInitial = initialLabel ?? LabelModelFactory.createNew(mode, dataId: data.dataId);

    debugPrint('[LabelVMFactory] mode=$mode, data=${data.fileName}');

    switch (mode) {
      case LabelingMode.singleClassification:
      case LabelingMode.multiClassification:
        return ClassificationLabelViewModel(project: project, data: data, labelUseCases: labelUseCases, initialLabel: resolvedInitial, mapper: resolvedMapper);

      case LabelingMode.crossClassification:
        // ⚠️ 주의: CrossClassification의 경우 UnifiedData가 "쌍"을 표현해야 함
        // (예: UnifiedDataPair 또는 data.meta에 pair 정보 포함).
        return CrossClassificationLabelViewModel(
            project: project, data: data, labelUseCases: labelUseCases, initialLabel: resolvedInitial, mapper: resolvedMapper);

      case LabelingMode.singleClassSegmentation:
      case LabelingMode.multiClassSegmentation:
        return SegmentationLabelViewModel(project: project, data: data, labelUseCases: labelUseCases, initialLabel: resolvedInitial, mapper: resolvedMapper);
    }
  }
}
