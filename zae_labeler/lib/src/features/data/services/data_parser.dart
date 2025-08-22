import 'dart:convert';

import '../../../core/models/data/file_type.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/data/unified_data.dart';

abstract class DataParser {
  UnifiedData parse({required DataInfo info, required FileType type, required String? raw});
}

class DefaultDataParser implements DataParser {
  @override
  UnifiedData parse({required DataInfo info, required FileType type, required String? raw}) {
    switch (type) {
      case FileType.series:
        return UnifiedData(dataInfo: info, fileType: type, seriesData: _parseCsv(raw ?? ''));
      case FileType.object:
        return UnifiedData(dataInfo: info, fileType: type, objectData: _parseJson(raw ?? ''));
      case FileType.image:
        // raw는 base64로 유지
        return UnifiedData(dataInfo: info, fileType: type, imageBase64: raw);
      case FileType.unsupported:
        return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
    }
  }

  List<double> _parseCsv(String content) {
    final lines = content.split('\n');
    return lines.expand((l) => l.split(',')).map((v) => double.tryParse(v.trim()) ?? 0.0).toList();
  }

  Map<String, dynamic> _parseJson(String content) {
    try {
      final v = jsonDecode(content);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
