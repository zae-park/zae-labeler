// 📁 sub_view_models/segmentation_label_view_model.dart

import 'package:zae_labeler/src/features/label/logic/label_input_mapper.dart';

import '../../../../core/models/project/project_model.dart';
import '../../../../core/models/data/unified_data.dart';

import '../../../../core/models/label/label_model.dart';
import '../../../../core/models/label/segmentation_label_model.dart';
import 'base_label_view_model.dart';

/// ViewModel for segmentation labeling.
/// Handles pixel-level updates and repository-backed I/O.
class SegmentationLabelViewModel extends LabelViewModel {
  SegmentationLabelViewModel(
      {required Project project, required UnifiedData data, required super.labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper})
      : super(project: project, data: data, initialLabel: initialLabel, mapper: mapper ?? LabelInputMapper.forMode(project.mode));

  /// 현재 라벨을 세그멘테이션 모델로 캐스팅(타입 안전성 보장)
  SegmentationLabelModel<SegmentationData> get _seg => labelModel as SegmentationLabelModel<SegmentationData>;

  /// label이 null이면 "빈 세그멘테이션 데이터"로 대체
  /// (SegmentationData는 width/height 메타가 필요 없음)
  SegmentationData _ensureData(SegmentationLabelModel<SegmentationData> m) => m.label ?? SegmentationData.empty;

  @override
  Future<void> addPixel(int x, int y, String classLabel) async {
    final nextData = _ensureData(_seg).addPixel(x, y, classLabel);
    final nextModel = _seg.copyWith(labeledAt: DateTime.now(), label: nextData);
    await updateLabel(nextModel);
  }

  @override
  Future<void> removePixel(int x, int y) async {
    final nextData = _ensureData(_seg).removePixel(x, y);
    final nextModel = _seg.copyWith(labeledAt: DateTime.now(), label: nextData);
    await updateLabel(nextModel);
  }
}
