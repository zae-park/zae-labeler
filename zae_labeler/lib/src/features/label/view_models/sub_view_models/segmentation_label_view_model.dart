// 📁 sub_view_models/segmentation_label_view_model.dart

import 'package:zae_labeler/src/features/label/logic/label_input_mapper.dart';

import '../../../../core/models/project/project_model.dart';
import '../../../../core/models/data/unified_data.dart';

import '../../models/label_model.dart';
import '../../models/sub_models/segmentation_label_model.dart';
import 'base_label_view_model.dart';

/// ViewModel for segmentation labeling.
/// Handles pixel-level updates and repository-backed I/O.
class SegmentationLabelViewModel extends LabelViewModel {
  SegmentationLabelViewModel(
      {required Project project, required UnifiedData data, required super.labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper})
      : super(project: project, data: data, initialLabel: initialLabel, mapper: mapper ?? LabelInputMapper.forMode(project.mode));

  /// 현재 라벨을 세그멘테이션 모델로 캐스팅(타입 안전성 보장)
  SegmentationLabelModel get _seg => labelModel as SegmentationLabelModel;

  /// label이 null이면 캔버스 크기에 맞는 빈 데이터로 초기화
  SegmentationData _ensureData(SegmentationLabelModel m) {
    return m.label ?? SegmentationData.empty(width: data.width, height: data.height);
  }

  bool _inBounds(int x, int y) {
    // 필요한 경우 경계 체크 (UnifiedData에 width/height가 없으면 생략 가능)
    if (data.width == null || data.height == null) return true;
    return x >= 0 && y >= 0 && x < data.width! && y < data.height!;
  }

  @override
  Future<void> addPixel(int x, int y, String classLabel) async {
    if (!_inBounds(x, y)) return;

    final prev = _seg;
    final baseData = _ensureData(prev);

    // SegmentationData가 불변이라면 addPixel이 새 인스턴스를 반환한다고 가정
    // (가변이면 복제 후 변경하는 쪽으로 구현)
    final nextData = baseData.addPixel(x, y, classLabel);

    final nextModel = prev.copyWith(labeledAt: DateTime.now(), label: nextData);

    await updateLabel(nextModel);
  }

  @override
  Future<void> removePixel(int x, int y) async {
    if (!_inBounds(x, y)) return;

    final prev = _seg;
    final baseData = _ensureData(prev);
    final nextData = baseData.removePixel(x, y);

    final nextModel = prev.copyWith(labeledAt: DateTime.now(), label: nextData);

    await updateLabel(nextModel);
  }
}
