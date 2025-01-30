// lib/src/models/label_entry.dart

/*
이 파일은 데이터 파일에 대한 라벨 정보를 정의합니다.
LabelEntry 클래스는 단일 분류, 다중 분류, 세그멘테이션과 같은 다양한 라벨링 작업을 지원합니다.
라벨 엔트리와 관련된 JSON 직렬화 및 역직렬화를 포함합니다.
*/

/// Represents a label entry for a specific data file.
/// Contains information about the file and its associated labels.
class LabelEntry {
  String dataFilename; // Name of the data file
  String dataPath; // Path to the data file
  SingleClassificationLabel? singleClassification; // Label for single classification tasks
  MultiClassificationLabel? multiClassification; // Labels for multi-classification tasks
  SegmentationLabel? segmentation; // Label for segmentation tasks

  LabelEntry({required this.dataFilename, required this.dataPath, this.singleClassification, this.multiClassification, this.segmentation});

  /// Converts the label entry into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'data_filename': dataFilename,
        'data_path': dataPath,
        'single_classification': singleClassification?.toJson(),
        'multi_classification': multiClassification?.toJson(),
        'segmentation': segmentation?.toJson(),
      };

  /// Creates a label entry from a JSON-compatible map.
  factory LabelEntry.fromJson(Map<String, dynamic> json) => LabelEntry(
        dataFilename: json['data_filename'] ?? 'unknown.json', // ✅ 기본값 설정
        dataPath: json['data_path'] ?? 'unknown_path', // ✅ 기본값 설정
        singleClassification: json['single_classification'] != null ? SingleClassificationLabel.fromJson(json['single_classification']) : null,
        multiClassification: json['multi_classification'] != null ? MultiClassificationLabel.fromJson(json['multi_classification']) : null,
        segmentation: json['segmentation'] != null ? SegmentationLabel.fromJson(json['segmentation']) : null,
      );
}

/// Represents a label for a single classification task.
class SingleClassificationLabel {
  String labeledAt; // Timestamp when the label was created
  String label; // The assigned label

  SingleClassificationLabel({required this.labeledAt, required this.label});

  /// Converts the single classification label into a JSON-compatible map.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label};

  /// Creates a single classification label from a JSON-compatible map.
  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) => SingleClassificationLabel(labeledAt: json['labeled_at'], label: json['label']);
}

/// Represents labels for a multi-classification task.
class MultiClassificationLabel {
  String labeledAt; // Timestamp when the labels were created
  List<String> labels; // List of assigned labels

  MultiClassificationLabel({required this.labeledAt, required this.labels});

  /// Converts the multi-classification label into a JSON-compatible map.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': labels};

  /// Creates a multi-classification label from a JSON-compatible map.
  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) => MultiClassificationLabel(
        labeledAt: json['labeled_at'],
        labels: List<String>.from(json['label']),
      );
}

/// Represents a label for a segmentation task.
class SegmentationLabel {
  String labeledAt; // Timestamp when the label was created
  SegmentationData label; // Segmentation data associated with the label

  SegmentationLabel({required this.labeledAt, required this.label});

  /// Converts the segmentation label into a JSON-compatible map.
  Map<String, dynamic> toJson() => {'labeled_at': labeledAt, 'label': label.toJson()};

  /// Creates a segmentation label from a JSON-compatible map.
  factory SegmentationLabel.fromJson(Map<String, dynamic> json) => SegmentationLabel(
        labeledAt: json['labeled_at'],
        label: SegmentationData.fromJson(json['label']),
      );
}

/// Represents segmentation data, including indices and classes.
class SegmentationData {
  List<String> indice; // List of indices for segmentation
  List<String> classes; // List of class labels for segmentation

  SegmentationData({required this.indice, required this.classes});

  /// Converts the segmentation data into a JSON-compatible map.
  Map<String, dynamic> toJson() => {'indice': indice, 'classes': classes};

  /// Creates segmentation data from a JSON-compatible map.
  factory SegmentationData.fromJson(Map<String, dynamic> json) => SegmentationData(
        indice: List<String>.from(json['indice']),
        classes: List<String>.from(json['classes']),
      );
}
