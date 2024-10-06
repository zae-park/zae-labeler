// lib/src/models/label_entry.dart

class LabelEntry {
  String dataFilename;
  String dataPath;
  SingleClassificationLabel? singleClassification;
  MultiClassificationLabel? multiClassification;
  SegmentationLabel? segmentation;

  LabelEntry({
    required this.dataFilename,
    required this.dataPath,
    this.singleClassification,
    this.multiClassification,
    this.segmentation,
  });

  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'single_classification': singleClassification?.toJson(),
        'multi_classification': multiClassification?.toJson(),
        'segmentation': segmentation?.toJson(),
      };

  factory LabelEntry.fromJson(Map<String, dynamic> json) => LabelEntry(
        dataFilename: json['data_filename'],
        dataPath: json['data_path'],
        singleClassification: json['single_classification'] != null
            ? SingleClassificationLabel.fromJson(json['single_classification'])
            : null,
        multiClassification: json['multi_classification'] != null
            ? MultiClassificationLabel.fromJson(json['multi_classification'])
            : null,
        segmentation: json['segmentation'] != null
            ? SegmentationLabel.fromJson(json['segmentation'])
            : null,
      );
}

class SingleClassificationLabel {
  String labeledAt;
  String label;

  SingleClassificationLabel({
    required this.labeledAt,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'labeled_at': labeledAt,
        'label': label,
      };

  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) =>
      SingleClassificationLabel(
        labeledAt: json['labeled_at'],
        label: json['label'],
      );
}

class MultiClassificationLabel {
  String labeledAt;
  List<String> labels;

  MultiClassificationLabel({
    required this.labeledAt,
    required this.labels,
  });

  Map<String, dynamic> toJson() => {
        'labeled_at': labeledAt,
        'label': labels,
      };

  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassificationLabel(
        labeledAt: json['labeled_at'],
        labels: List<String>.from(json['label']),
      );
}

class SegmentationLabel {
  String labeledAt;
  SegmentationData label;

  SegmentationLabel({
    required this.labeledAt,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'labeled_at': labeledAt,
        'label': label.toJson(),
      };

  factory SegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SegmentationLabel(
        labeledAt: json['labeled_at'],
        label: SegmentationData.fromJson(json['label']),
      );
}

class SegmentationData {
  List<String> indice;
  List<String> classes;

  SegmentationData({
    required this.indice,
    required this.classes,
  });

  Map<String, dynamic> toJson() => {
        'indice': indice,
        'classes': classes,
      };

  factory SegmentationData.fromJson(Map<String, dynamic> json) =>
      SegmentationData(
        indice: List<String>.from(json['indice']),
        classes: List<String>.from(json['classes']),
      );
}
