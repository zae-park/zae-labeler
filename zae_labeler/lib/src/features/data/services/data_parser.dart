// 원문 문자열 + 파일명/타입을 받아 UnifiedData를 생성.
// - csv → seriesData
// - json → objectData
// - image → imageBase64
import 'dart:convert';

import '../../../core/models/data/file_type.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/data/unified_data.dart';

abstract class DataParser {
  UnifiedData parse({
    required DataInfo info,
    required FileType fileType,
    required String? raw, // base64 or plain text
  });
}

class DefaultDataParser implements DataParser {
  @override
  UnifiedData parse({required DataInfo info, required FileType fileType, required String? raw}) {
    switch (fileType) {
      case FileType.series:
        return UnifiedData(dataInfo: info, fileType: fileType, seriesData: _parseSeries(raw ?? ''));
      case FileType.object:
        return UnifiedData(dataInfo: info, fileType: fileType, objectData: _parseJsonObject(raw ?? ''));
      case FileType.image:
        // raw는 base64 문자열이라고 가정 (web 업로드 그대로 유지)
        return UnifiedData(dataInfo: info, fileType: fileType, imageBase64: raw);
      case FileType.unsupported:
        return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
    }
  }

  List<double> _parseSeries(String content) {
    // csv 파싱(아주 단순 버전). 실제로는 csv 패키지 사용 권장.
    final lines = content.split('\n');
    return lines.expand((line) => line.split(',')).map((v) => double.tryParse(v.trim()) ?? 0.0).toList();
  }

  Map<String, dynamic> _parseJsonObject(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
