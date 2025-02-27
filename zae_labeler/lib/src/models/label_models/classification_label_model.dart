import 'label_model.dart';

//// ✅ Classification Label의 최상위 클래스
abstract class ClassificationLabel extends LabelModel {
  dynamic labelData; // ✅ 추가 (단일 문자열 or 리스트)

  ClassificationLabel({required super.labeledAt, required this.labelData});
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabel extends ClassificationLabel {
  SingleClassificationLabel({required super.labeledAt, required String label}) : super(labelData: label);

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': labelData};
  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) => SingleClassificationLabel(labeledAt: json['labeled_at'], label: json['label']);
  factory SingleClassificationLabel.empty() => SingleClassificationLabel(labeledAt: '', label: '');
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabel extends ClassificationLabel {
  MultiClassificationLabel({required super.labeledAt, required List<String> labels}) : super(labelData: labels);

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'labels': labelData};
  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassificationLabel(labeledAt: json['labeled_at'], labels: List<String>.from(json['labels']));
  factory MultiClassificationLabel.empty() => MultiClassificationLabel(labeledAt: '', labels: []);
}

/// ✅ 크로스 분류 (Cross Classification) - 추후 업데이트
class CrossClassificationLabel extends ClassificationLabel {
  CrossClassificationLabel({required super.labeledAt, required List<String> dataPairs}) : super(labelData: dataPairs);

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'data_pairs': labelData};
  factory CrossClassificationLabel.fromJson(Map<String, dynamic> json) =>
      CrossClassificationLabel(labeledAt: json['labeled_at'], dataPairs: List<String>.from(json['data_pairs']));
  factory CrossClassificationLabel.empty() => CrossClassificationLabel(labeledAt: '', dataPairs: []);
}
