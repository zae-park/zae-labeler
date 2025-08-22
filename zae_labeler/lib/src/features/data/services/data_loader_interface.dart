// lib/src/features/data/services/data_loader_interface.dart
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

/// 플랫폼에 따라 실제 I/O를 수행해 UnifiedData를 만들어주는 인터페이스
abstract class DataLoader {
  Future<UnifiedData> fromDataInfo(DataInfo info);
}
