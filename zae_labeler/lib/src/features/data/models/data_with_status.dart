// lib/src/features/data/models/data_with_status.dart
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart'; // LabelStatus

class DataWithStatus {
  final UnifiedData data;
  final LabelStatus status;

  const DataWithStatus({required this.data, required this.status});
}
