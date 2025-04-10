import 'package:flutter/material.dart';

import 'base_label_model.dart';

/// ✅ ClassificationLabelModel: 분류(Label) 모델의 상위 클래스
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.label, required super.labeledAt});
  LabelModel toggleLabel(String labelItem);
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  @override
  Map<String, dynamic> toJson() => {'label': label, 'labeled_at': labeledAt.toIso8601String()};

  @override
  factory SingleClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabelModel(label: json['label'] as String, labeledAt: json['labels']);
  }

  @override
  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(labeledAt: DateTime.now(), label: 'empty');
  }

  @override
  SingleClassificationLabelModel updateLabel(String labelData) {
    return SingleClassificationLabelModel(labeledAt: DateTime.now(), label: labelData);
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
  Map<String, dynamic> toJson() => {'label': label.toList(), 'labeled_at': labeledAt.toIso8601String()};

  /// ✅ `fromJson()` 구현
  @override
  factory MultiClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return MultiClassificationLabelModel(label: Set<String>.from(json['labels']), labeledAt: json['labeled_at']);
  }

  /// ✅ `empty()` 구현
  @override
  factory MultiClassificationLabelModel.empty() => MultiClassificationLabelModel(labeledAt: DateTime.now(), label: {});

  @override
  MultiClassificationLabelModel updateLabel(Set<String> labelData) => MultiClassificationLabelModel(labeledAt: DateTime.now(), label: labelData);

  @override
  LabelModel toggleLabel(String labelItem) {
    final updated = Set<String>.from(label);
    if (updated.contains(labelItem)) {
      updated.remove(labelItem);
    } else {
      updated.add(labelItem);
    }
    return updateLabel(updated);
  }

  @override
  // bool isSelected(Set<String> labelData) => labelData.every(label.contains); // ✅ 다중 값 비교
  bool isSelected(dynamic labelData) {
    if (labelData is String) {
      final result = label.contains(labelData);
      debugPrint("[isSelected] labelItem: $labelData → $result");
      return result;
    } else if (labelData is Set<String>) {
      final result = labelData.every(label.contains);
      debugPrint("[isSelected] labelItem: $labelData → $result");
      return result;
    }
    debugPrint("[isSelected] labelItem: $labelData → False");
    return false;
  }
}

// /// ✅ 크로스 분류 (Cross Classification) - 추후 업데이트
// class CrossClassificationLabel extends ClassificationLabel {
//   CrossClassificationLabel({required super.labeledAt, required List<String> dataPairs}) : super(labelData: dataPairs);

//   @override
//   Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'data_pairs': labelData};
//   factory CrossClassificationLabel.fromJson(Map<String, dynamic> json) =>
//       CrossClassificationLabel(labeledAt: json['labeled_at'], dataPairs: List<String>.from(json['data_pairs']));
//   factory CrossClassificationLabel.empty() => CrossClassificationLabel(labeledAt: '', dataPairs: []);
// }
