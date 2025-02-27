import 'label_model.dart';

/// ✅ Segmentation Label의 최상위 클래스
abstract class SegmentationLabel extends LabelModel {
  SegmentationData labelData;

  SegmentationLabel({required super.labeledAt, required this.labelData});
}

/// ✅ 단일 클래스 세그멘테이션 (Single-Class Segmentation)
class SingleClassSegmentationLabel extends SegmentationLabel {
  SingleClassSegmentationLabel({required super.labeledAt, required super.labelData});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label_data': labelData.toJson()};

  factory SingleClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SingleClassSegmentationLabel(labeledAt: json['labeled_at'], labelData: SegmentationData.fromJson(json['label_data']));
}

/// ✅ 다중 클래스 세그멘테이션 (Multi-Class Segmentation) - 추후 업데이트
class MultiClassSegmentationLabel extends SegmentationLabel {
  MultiClassSegmentationLabel({required super.labeledAt, required super.labelData});

  @override
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label_data': labelData.toJson()};

  factory MultiClassSegmentationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassSegmentationLabel(labeledAt: json['labeled_at'], labelData: SegmentationData.fromJson(json['label_data']));
}

/// ✅ 세그멘테이션 데이터 구조
class SegmentationData {
  List<Segment> segments;

  SegmentationData({required this.segments});

  Map<String, dynamic> toJson() => {'segments': segments.map((s) => s.toJson()).toList()};

  factory SegmentationData.fromJson(Map<String, dynamic> json) => SegmentationData(
        segments: (json['segments'] as List).map((s) => Segment.fromJson(s)).toList(),
      );
}

/// ✅ 개별 세그먼트 데이터 구조
class Segment {
  List<int> indices; // 선택된 픽셀 또는 영역의 인덱스
  String classLabel; // 해당 영역의 클래스

  Segment({required this.indices, required this.classLabel});

  Map<String, dynamic> toJson() => {'indices': indices, 'class_label': classLabel};

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(indices: List<int>.from(json['indices']), classLabel: json['class_label']);
}
