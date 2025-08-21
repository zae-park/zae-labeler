// lib/src/core/models/label/segmentation_label_model.dart

import 'label_types.dart';
import 'base_label_model.dart';
import 'segmentation_data.dart';

/// ✅ Segmentation Label의 최상위 클래스
/// - 세그멘테이션 계열 라벨 모델의 공통 기반.
/// - 제네릭 T는 SegmentationData 파생 타입으로 제한.
/// - `toPayloadJson()`은 라벨 **페이로드만** 반환합니다(래퍼 X).
abstract class SegmentationLabelModel<T extends SegmentationData> extends LabelModel<T> {
  SegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  /// 변경된 시각/라벨만 교체한 새 인스턴스를 반환.
  SegmentationLabelModel<T> copyWith({DateTime? labeledAt, T? label});

  @override
  LabelingMode get mode;

  @override
  bool get isMultiClass;

  @override
  bool get isLabeled;
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  SingleClassSegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode => LabelingMode.singleClassSegmentation;

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  /// ⚠️ 페이로드만 반환합니다. (래퍼 키 포함 금지)
  /// 예: { "segments": { ... } }
  @override
  Map<String, dynamic> toPayloadJson() => label?.toJson() ?? const <String, dynamic>{};

  /// ⚠️ `payload`는 **label_data**에 해당하는 JSON이어야 합니다.
  /// 즉, `{"segments": {...}}` 같은 형태만 받습니다.
  /// (누락/빈 객체일 경우 안전하게 빈 마스크로 복원)
  factory SingleClassSegmentationLabelModel.fromPayloadJson(
      {required String dataId, String? dataPath, required DateTime labeledAt, required Map<String, dynamic> payload}) {
    final seg = (payload['segments'] is Map) ? SegmentationData.fromJson(payload) : const SegmentationData(segments: {});
    return SingleClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: seg, labeledAt: labeledAt);
  }

  @override
  SingleClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) {
    return SingleClassSegmentationLabelModel(
      dataId: dataId,
      dataPath: dataPath,
      labeledAt: labeledAt ?? this.labeledAt,
      label: label ?? this.label,
    );
  }
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation)
class MultiClassSegmentationLabelModel extends SegmentationLabelModel<SegmentationData> {
  MultiClassSegmentationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode => LabelingMode.multiClassSegmentation;

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  /// ⚠️ 페이로드만 반환합니다. (래퍼 키 포함 금지)
  @override
  Map<String, dynamic> toPayloadJson() => label?.toJson() ?? const <String, dynamic>{};

  /// ⚠️ `payload`는 **label_data**에 해당하는 JSON이어야 합니다.
  /// (누락/빈 객체일 경우 안전하게 빈 마스크로 복원)
  factory MultiClassSegmentationLabelModel.fromPayloadJson(
      {required String dataId, String? dataPath, required DateTime labeledAt, required Map<String, dynamic> payload}) {
    final seg = (payload['segments'] is Map) ? SegmentationData.fromJson(payload) : const SegmentationData(segments: {});
    return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, label: seg, labeledAt: labeledAt);
  }

  @override
  MultiClassSegmentationLabelModel copyWith({DateTime? labeledAt, SegmentationData? label}) {
    return MultiClassSegmentationLabelModel(dataId: dataId, dataPath: dataPath, labeledAt: labeledAt ?? this.labeledAt, label: label ?? this.label);
  }
}
