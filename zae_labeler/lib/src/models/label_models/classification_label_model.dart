import 'label_model.dart';

/// ✅ ClassificationLabelModel: 분류(Label) 모델의 상위 클래스
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.labeledAt});

  /// ✅ 단일/다중 분류 여부 (각 서브클래스에서 오버라이드 가능)
  bool get isMultiClass;

  @override
  Map<String, dynamic> toJson();
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  final bool _isMultiClass = false;
  final String label;

  SingleClassificationLabelModel({required super.labeledAt, required this.label});

  @override
  bool get isMultiClass => _isMultiClass;

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label};

  @override
  factory SingleClassificationLabelModel.fromJson(Map<String, dynamic> json) {
    return SingleClassificationLabelModel(labeledAt: json['labeled_at'], label: json['label']);
  }

  @override
  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(labeledAt: '', label: '');
  }

  @override
  SingleClassificationLabelModel updateLabel(String labelData) {
    return SingleClassificationLabelModel(labeledAt: DateTime.now().toIso8601String(), label: labelData);
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
