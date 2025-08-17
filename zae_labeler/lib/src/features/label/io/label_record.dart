// lib/src/features/label/io/label_record.dart
class LabelRecord {
  final String dataId;
  final String? dataPath;
  final String? mode; // optional
  final DateTime labeledAt;
  final Map<String, dynamic> labelData;

  LabelRecord({required this.dataId, this.dataPath, this.mode, required this.labeledAt, required this.labelData});

  Map<String, dynamic> toJson() => {'data_id': dataId, 'data_path': dataPath, 'labeled_at': labeledAt.toIso8601String(), 'mode': mode, 'label_data': labelData};

  factory LabelRecord.fromJson(Map<String, dynamic> j) => LabelRecord(
        dataId: j['data_id'] as String,
        dataPath: j['data_path'] as String?,
        mode: j['mode'] as String?,
        labeledAt: DateTime.tryParse(j['labeled_at'] as String? ?? '') ?? DateTime.now(),
        labelData: Map<String, dynamic>.from(j['label_data'] as Map? ?? const {}),
      );
}
