// core/models/label/classification_label_model.dart

import 'base_label_model.dart';
import 'label_types.dart';

abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  LabelingMode get mode; // 서브클래스가 명시
}

/// Single Classification
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => (label?.trim().isNotEmpty ?? false);

  @override
  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'label': label, 'labeled_at': labeledAt.toIso8601String()};

  factory SingleClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabelModel(
      dataId: json['data_id'] as String,
      dataPath: json['data_path'] as String?,
      label: json['label'] as String?,
      labeledAt: DateTime.parse(json['labeled_at'] as String),
    );
  }

  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  LabelingMode get mode => LabelingMode.singleClassification;
}

/// Multi Classification
class MultiClassificationLabelModel extends ClassificationLabelModel<Set<String>> {
  MultiClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => (label != null && label!.isNotEmpty);

  @override
  Map<String, dynamic> toJson() => {
        'data_id': dataId,
        'data_path': dataPath,
        'label': label?.toList(),
        'labeled_at': labeledAt.toIso8601String(),
      };

  factory MultiClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    final raw = json['label'];
    return MultiClassificationLabelModel(
      dataId: json['data_id'] as String,
      dataPath: json['data_path'] as String?,
      label: raw == null ? null : Set<String>.from(raw as List),
      labeledAt: DateTime.parse(json['labeled_at'] as String),
    );
  }

  factory MultiClassificationLabelModel.empty() {
    return MultiClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  LabelingMode get mode => LabelingMode.multiClassification;
}

/// Cross Classification
class CrossClassificationLabelModel extends ClassificationLabelModel<CrossDataPair> {
  CrossClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label != null && (label!.relation.isNotEmpty);

  @override
  Map<String, dynamic> toJson() => {
        'data_id': dataId,
        'data_path': dataPath,
        'sourceId': label?.sourceId,
        'targetId': label?.targetId,
        'relation': label?.relation,
        'labeled_at': labeledAt.toIso8601String(),
      };

  factory CrossClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return CrossClassificationLabelModel(
      dataId: json['data_id'] as String,
      dataPath: json['data_path'] as String?,
      label: (json['sourceId'] != null || json['targetId'] != null || json['relation'] != null)
          ? CrossDataPair(
              sourceId: (json['sourceId'] ?? '') as String,
              targetId: (json['targetId'] ?? '') as String,
              relation: (json['relation'] ?? '') as String,
            )
          : null,
      labeledAt: DateTime.parse(json['labeled_at'] as String),
    );
  }

  factory CrossClassificationLabelModel.empty() {
    return CrossClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  LabelingMode get mode => LabelingMode.crossClassification;
}

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
