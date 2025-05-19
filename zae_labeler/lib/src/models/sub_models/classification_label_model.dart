import 'package:zae_labeler/src/models/label_model.dart';

import 'base_label_model.dart';

/// ✅ ClassificationLabelModel: 분류(Label) 모델의 상위 클래스
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  LabelModel toggleLabel(String labelItem);
  bool isSelected(String labelData);
  @override
  LabelingMode get mode => throw UnimplementedError('mode must be implemented in subclasses.');
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label?.trim().isNotEmpty == true;

  @override
  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'label': label, 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory SingleClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabelModel(
        dataId: json['data_id'], dataPath: json['data_path'], label: json['label'], labeledAt: DateTime.parse(json['labeled_at']));
  }

  @override
  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  SingleClassificationLabelModel updateLabel(String labelData) {
    return SingleClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: labelData, labeledAt: DateTime.now());
  }

  @override
  LabelModel toggleLabel(String labelItem) => updateLabel(labelItem);

  @override
  bool isSelected(String labelData) => label == labelData;

  @override
  LabelingMode get mode => LabelingMode.singleClassification;
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabelModel extends ClassificationLabelModel<Set<String>> {
  MultiClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'label': label?.toList(), 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory MultiClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return MultiClassificationLabelModel(
        dataId: json['data_id'], dataPath: json['data_path'], label: Set<String>.from(json['label']), labeledAt: DateTime.parse(json['labeled_at']));
  }

  @override
  factory MultiClassificationLabelModel.empty() =>
      MultiClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));

  @override
  MultiClassificationLabelModel updateLabel(Set<String> labelData) =>
      MultiClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: labelData, labeledAt: DateTime.now());

  @override
  LabelModel toggleLabel(String labelItem) {
    final updated = Set<String>.from(label ?? {});
    if (updated.contains(labelItem)) {
      updated.remove(labelItem);
    } else {
      updated.add(labelItem);
    }
    return updateLabel(updated);
  }

  @override
  bool isSelected(String labelData) => label?.contains(labelData) ?? false;

  @override
  LabelingMode get mode => LabelingMode.multiClassification;
}

/// ✅ 크로스 분류 (Cross Classification)
class CrossClassificationLabelModel extends ClassificationLabelModel<CrossDataPair> {
  CrossClassificationLabelModel({required super.dataId, super.dataPath, required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label != null && label!.relation.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'data_id': dataId,
        'data_path': dataPath,
        'sourceId': label?.sourceId,
        'targetId': label?.targetId,
        'relation': label?.relation,
        'labeled_at': labeledAt.toIso8601String(),
      };

  @override
  factory CrossClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return CrossClassificationLabelModel(
      dataId: json['data_id'],
      dataPath: json['data_path'],
      label: CrossDataPair(
        sourceId: json['sourceId'] ?? '',
        targetId: json['targetId'] ?? '',
        relation: json['relation'] ?? '',
      ),
      labeledAt: DateTime.parse(json['labeled_at']),
    );
  }

  @override
  factory CrossClassificationLabelModel.empty() {
    return CrossClassificationLabelModel(dataId: '', dataPath: null, label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  CrossClassificationLabelModel updateLabel(CrossDataPair labelData) =>
      CrossClassificationLabelModel(dataId: dataId, dataPath: dataPath, label: labelData, labeledAt: DateTime.now());

  @override
  LabelModel toggleLabel(String labelItem) {
    if (label == null) return this;
    return updateLabel(label!.copyWith(relation: labelItem));
  }

  @override
  bool isSelected(String labelData) => label?.relation == labelData;

  @override
  LabelingMode get mode => LabelingMode.crossClassification;
}

class CrossDataPair {
  final String sourceId;
  final String targetId;
  final String relation;

  const CrossDataPair({required this.sourceId, required this.targetId, required this.relation});

  CrossDataPair copyWith({String? sourceId, String? targetId, String? relation}) =>
      CrossDataPair(sourceId: sourceId ?? this.sourceId, targetId: targetId ?? this.targetId, relation: relation ?? this.relation);

  Map<String, dynamic> toJson() => {'sourceId': sourceId, 'targetId': targetId, 'relation': relation};

  factory CrossDataPair.fromJson(Map<String, dynamic> json) =>
      CrossDataPair(sourceId: json['sourceId'] ?? '', targetId: json['targetId'] ?? '', relation: json['relation'] ?? '');
}
