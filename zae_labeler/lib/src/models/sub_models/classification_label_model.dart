import 'base_label_model.dart';

/// ✅ ClassificationLabelModel: 분류(Label) 모델의 상위 클래스
abstract class ClassificationLabelModel<T> extends LabelModel<T> {
  ClassificationLabelModel({required super.label, required super.labeledAt});
}

/// ✅ 단일 분류 (Single Classification)
class SingleClassificationLabelModel extends ClassificationLabelModel<String> {
  SingleClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => false;

  // @override
  // Map<String, String> toJson() => {'labeled_at': labeledAt, 'label': label};

  // @override
  // factory SingleClassificationLabelModel.fromJson(Map<String, String> json) {
  //   return SingleClassificationLabelModel(label: json['label']!, labeledAt: json['labeled_at']!);
  // }

  @override
  factory SingleClassificationLabelModel.empty() {
    return SingleClassificationLabelModel(labeledAt: DateTime.now(), label: 'empty');
  }

  @override
  SingleClassificationLabelModel updateLabel(String labelData) {
    return SingleClassificationLabelModel(labeledAt: DateTime.now(), label: labelData);
  }

  @override
  bool isSelected(String labelData) => label == labelData; // ✅ 단일 값 비교
}

/// ✅ 다중 분류 (Multi Classification)
class MultiClassificationLabelModel extends ClassificationLabelModel<Set<String>> {
  MultiClassificationLabelModel({required super.label, required super.labeledAt});

  @override
  bool get isMultiClass => true;

  // @override
  // Map<String, List<String>> toJson() => {'label': label, 'labeled_at': labeledAt};

  // /// ✅ `fromJson()` 구현
  // @override
  // factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) {
  //   return MultiClassificationLabel(labeledAt: json['labeled_at'], labels: List<String>.from(json['labels']));
  // }

  /// ✅ `empty()` 구현
  @override
  factory MultiClassificationLabelModel.empty() => MultiClassificationLabelModel(labeledAt: DateTime.now(), label: {});

  @override
  MultiClassificationLabelModel updateLabel(Set<String> labelData) => MultiClassificationLabelModel(labeledAt: DateTime.now(), label: labelData);

  MultiClassificationLabelModel toggleLabel(String labelItem) {
    final newList = Set<String>.from(label);
    if (newList.contains(labelItem)) {
      newList.remove(labelItem);
    } else {
      newList.add(labelItem);
    }
    return MultiClassificationLabelModel(labeledAt: DateTime.now(), label: newList);
  }

  @override
  bool isSelected(Set<String> labelData) => labelData.every(label.contains); // ✅ 다중 값 비교
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
