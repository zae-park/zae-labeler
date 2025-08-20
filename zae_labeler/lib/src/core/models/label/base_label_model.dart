// lib/src/models/label_model.dart

/*
이 파일은 라벨링 모드 클래스를 위한 추상 클래스를 포함합니다.
*/

import 'label_model.dart';

/// ✅ LabelModel의 최상위 추상 클래스 (Base Model)
abstract class LabelModel<T> {
  final String dataId;
  final String? dataPath;
  final T? label;
  final DateTime labeledAt;

  LabelModel({required this.dataId, this.dataPath, required this.label, required this.labeledAt});

  bool get isMultiClass;
  T? get labelData => label;
  String get formattedLabeledAt => labeledAt.toIso8601String();

  bool get isLabeled;
  LabelingMode get mode;

  Map<String, dynamic> toJson();
  factory LabelModel.fromJson(Map<String, dynamic> json) => throw UnimplementedError('fromJson() must be implemented in subclasses.');
  factory LabelModel.empty() => throw UnimplementedError('fromJson() must be implemented in subclasses.');

  // LabelModel updateLabel(T labelData);
}
