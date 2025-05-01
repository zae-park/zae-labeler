import 'package:flutter/material.dart';

import 'base_label_model.dart';

/// ✅ ClassificationLabelModel: 분류(Label) 모델의 상위 클래스
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.label, required super.labeledAt});
  LabelModel toggleLabel(String labelItem);
  bool isSelected(String labelData);
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  bool get isLabeled => label?.trim().isNotEmpty == true;

  @override
  Map<String, dynamic> toJson() => {'label': label, 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory SingleClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabelModel(label: json['label'] as String, labeledAt: json['label']);
  }

  @override
  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  @override
  SingleClassificationLabelModel updateLabel(String labelData) {
    debugPrint("[ClsLabelM.updateLabel] labelData: $labelData");
    return SingleClassificationLabelModel(label: labelData, labeledAt: DateTime.now());
  }

  @override
  LabelModel toggleLabel(String labelItem) => updateLabel(labelItem);

  @override
  bool isSelected(String labelData) => label == labelData; // ✅ 단일 값 비교
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabelModel extends ClassificationLabelModel<Set<String>> {
  MultiClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  @override
  bool get isLabeled => label != null && label!.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {'label': label?.toList(), 'labeled_at': labeledAt.toIso8601String()};

  /// ✅ `fromJson()` 구현
  @override
  factory MultiClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return MultiClassificationLabelModel(label: Set<String>.from(json['label']), labeledAt: json['labeled_at']);
  }

  /// ✅ `empty()` 구현
  @override
  factory MultiClassificationLabelModel.empty() => MultiClassificationLabelModel(label: null, labeledAt: DateTime.fromMillisecondsSinceEpoch(0));

  @override
  MultiClassificationLabelModel updateLabel(Set<String> labelData) => MultiClassificationLabelModel(label: labelData, labeledAt: DateTime.now());

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
}

/// ✅ 크로스 분류 (Cross Classification)
class CrossClassificationLabelModel extends ClassificationLabelModel<CrossDataPair> {
  CrossClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false; // 관계는 단일 선택

  @override
  bool get isLabeled => label != null && label!.relation.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'sourceId': label?.sourceId,
        'targetId': label?.targetId,
        'relation': label?.relation,
        'labeled_at': labeledAt.toIso8601String(),
      };

  @override
  factory CrossClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return CrossClassificationLabelModel(
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
    return CrossClassificationLabelModel(
      label: null,
      labeledAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  CrossClassificationLabelModel updateLabel(CrossDataPair labelData) {
    return CrossClassificationLabelModel(label: labelData, labeledAt: DateTime.now());
  }

  @override
  LabelModel toggleLabel(String labelItem) {
    // 🔥 Cross에서는 toggle 개념 대신 직접 relation 업데이트
    if (label == null) return this;
    return updateLabel(label!.copyWith(relation: labelItem));
  }

  @override
  bool isSelected(String labelData) => label?.relation == labelData;
}

/// ✅ 데이터 쌍 모델
class CrossDataPair {
  final String sourceId;
  final String targetId;
  final String relation;

  const CrossDataPair({required this.sourceId, required this.targetId, required this.relation});

  CrossDataPair copyWith({String? sourceId, String? targetId, String? relation}) {
    return CrossDataPair(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      relation: relation ?? this.relation,
    );
  }

  Map<String, dynamic> toJson() => {'sourceId': sourceId, 'targetId': targetId, 'relation': relation};

  factory CrossDataPair.fromJson(Map<String, dynamic> json) {
    return CrossDataPair(
      sourceId: json['sourceId'] ?? '',
      targetId: json['targetId'] ?? '',
      relation: json['relation'] ?? '',
    );
  }
}
