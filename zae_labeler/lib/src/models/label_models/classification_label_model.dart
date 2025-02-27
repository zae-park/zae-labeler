import 'label_model.dart';

/// ✅ Classification Label의 최상위 클래스
abstract class ClassificationLabel extends LabelModel {
  ClassificationLabel({required super.labeledAt});
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabel extends ClassificationLabel {
  String label; // 단일 클래스로 지정된 라벨

  SingleClassificationLabel({required super.labeledAt, required this.label});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label};

  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) => SingleClassificationLabel(labeledAt: json['labeled_at'], label: json['label']);
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabel extends ClassificationLabel {
  List<String> labels; // 여러 개의 클래스를 지정할 수 있음

  MultiClassificationLabel({required super.labeledAt, required this.labels});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'labels': labels};

  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassificationLabel(labeledAt: json['labeled_at'], labels: List<String>.from(json['labels']));
}

/// ✅ 크로스 분류 (Cross Classification) - 추후 업데이트
class CrossClassificationLabel extends ClassificationLabel {
  List<String> dataPairs; // 데이터 쌍 간의 비교 라벨

  CrossClassificationLabel({required super.labeledAt, required this.dataPairs});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'data_pairs': dataPairs};

  factory CrossClassificationLabel.fromJson(Map<String, dynamic> json) =>
      CrossClassificationLabel(labeledAt: json['labeled_at'], dataPairs: List<String>.from(json['data_pairs']));
}
