// lib/src/core/models/label/classification_label_model.dart

import 'base_label_model.dart';
import 'label_types.dart';

/// ✅ ClassificationLabelModel (추상)
/// - 분류(단일/다중/크로스) 라벨 모델의 공통 기반.
/// - **toJson()은 반드시 라벨 페이로드만 반환**합니다. (래퍼 키는 금지)
///   - Single: {"label": "..."}
///   - Multi : {"labels": ["...", "..."]}
///   - Cross : {"sourceId": "...", "targetId": "...", "relation": "..." }
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode; // 서브클래스에서 명시
}

/// ✅ Single Classification
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => (label?.trim().isNotEmpty ?? false);

  /// ⚠️ 페이로드만 반환합니다. (래퍼 키 포함 금지)
  /// 예: { "label": "cat" }
  @override
  Map<String, dynamic> toPayloadJson() => {'label': label};

  /// ⚠️ payload는 **label_data**에 해당하는 JSON이어야 합니다.
  /// 예: {"label": "cat"}
  factory SingleClassificationLabelModel.fromJsonPayload({
    required String dataId,
    String? dataPath,
    required DateTime labeledAt,
    required Map<String, dynamic> payload,
  }) {
    return SingleClassificationLabelModel(
      dataId: dataId,
      dataPath: dataPath,
      label: payload['label'] as String?,
      labeledAt: labeledAt,
    );
  }

  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(
      dataId: '',
      dataPath: null,
      label: null,
      labeledAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  LabelingMode get mode => LabelingMode.singleClassification;
}

/// ✅ Multi Classification
class MultiClassificationLabelModel extends ClassificationLabelModel<Set<String>> {
  MultiClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => (label != null && label!.isNotEmpty);

  /// ⚠️ 페이로드만 반환합니다. (래퍼 키 포함 금지)
  /// 예: { "labels": ["cat", "dog"] }
  @override
  Map<String, dynamic> toPayloadJson() => {'labels': label?.toList()};

  /// ⚠️ payload는 **label_data**에 해당하는 JSON이어야 합니다.
  /// 예: {"labels": ["cat","dog"]}
  factory MultiClassificationLabelModel.fromJsonPayload({
    required String dataId,
    String? dataPath,
    required DateTime labeledAt,
    required Map<String, dynamic> payload,
  }) {
    final raw = payload['labels'];
    return MultiClassificationLabelModel(
      dataId: dataId,
      dataPath: dataPath,
      label: raw == null ? null : Set<String>.from(raw as List),
      labeledAt: labeledAt,
    );
  }

  factory MultiClassificationLabelModel.empty() {
    return MultiClassificationLabelModel(
      dataId: '',
      dataPath: null,
      label: null,
      labeledAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  LabelingMode get mode => LabelingMode.multiClassification;
}

/// ✅ Cross Classification
class CrossClassificationLabelModel extends ClassificationLabelModel<CrossDataPair> {
  CrossClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label != null && (label!.relation.isNotEmpty);

  /// ⚠️ 페이로드만 반환합니다. (래퍼 키 포함 금지)
  /// 예: { "sourceId": "...", "targetId": "...", "relation": "..." }
  @override
  Map<String, dynamic> toPayloadJson() => label?.toJson() ?? <String, dynamic>{};

  /// ⚠️ payload는 **label_data**에 해당하는 JSON이어야 합니다.
  /// 예: {"sourceId":"...", "targetId":"...", "relation":"..."}
  factory CrossClassificationLabelModel.fromJsonPayload({
    required String dataId,
    String? dataPath,
    required DateTime labeledAt,
    required Map<String, dynamic> payload,
  }) {
    return CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: CrossDataPair.fromJson(payload), labeledAt: labeledAt);
  }

  factory CrossClassificationLabelModel.empty() {
    return CrossClassificationLabelModel(
      dataId: '',
      dataPath: null,
      label: null,
      labeledAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  LabelingMode get mode => LabelingMode.crossClassification;
}

/// ✅ Cross 데이터 쌍(관계 기반 분류) DTO
class CrossDataPair {
  final String sourceId;
  final String targetId;
  final String relation;

  const CrossDataPair({required this.sourceId, required this.targetId, this.relation = ''});

  CrossDataPair copyWith({String? sourceId, String? targetId, String? relation}) => CrossDataPair(
        sourceId: sourceId ?? this.sourceId,
        targetId: targetId ?? this.targetId,
        relation: relation ?? this.relation,
      );

  Map<String, dynamic> toJson() => {'sourceId': sourceId, 'targetId': targetId, 'relation': relation};

  factory CrossDataPair.fromJson(Map<String, dynamic> json) => CrossDataPair(
        sourceId: (json['sourceId'] ?? '') as String,
        targetId: (json['targetId'] ?? '') as String,
        relation: (json['relation'] ?? '') as String,
      );
}
