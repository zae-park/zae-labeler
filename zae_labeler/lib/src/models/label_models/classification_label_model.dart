import 'label_model.dart';

//// ✅ Classification Label의 최상위 클래스
abstract class ClassificationLabel extends LabelModel {
  ClassificationLabel({required super.labeledAt});
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabel extends ClassificationLabel {
  final String label;

  SingleClassificationLabel({required super.labeledAt, required this.label});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label};

  /// ✅ `fromJson()` 구현
  @override
  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabel(labeledAt: json['labeled_at'], label: json['label']);
  }

  /// ✅ `empty()` 구현
  @override
  factory SingleClassificationLabel.empty() {
    return SingleClassificationLabel(labeledAt: '', label: '');
  }

  SingleClassificationLabel updateLabel(String newLabel) {
    return SingleClassificationLabel(labeledAt: DateTime.now().toIso8601String(), label: newLabel);
  }
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabel extends ClassificationLabel {
  final List<String> labels;

  MultiClassificationLabel({required super.labeledAt, required this.labels});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'labels': labels};

  /// ✅ `fromJson()` 구현
  @override
  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) {
    return MultiClassificationLabel(labeledAt: json['labeled_at'], labels: List<String>.from(json['labels']));
  }

  /// ✅ `empty()` 구현
  @override
  factory MultiClassificationLabel.empty() {
    return MultiClassificationLabel(labeledAt: '', labels: []);
  }

  MultiClassificationLabel updateLabel(List<String> newLabels) {
    return MultiClassificationLabel(labeledAt: DateTime.now().toIso8601String(), labels: newLabels);
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
