// lib/src/features/data/services/data_loader_io.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';
import 'dart:convert' show base64Encode, jsonDecode;

import 'package:path/path.dart' as p;

import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

import 'data_loader_interface.dart';

class IoDataLoader implements DataLoader {
  @override
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    final filePath = info.filePath;
    if (filePath == null || filePath.isEmpty) {
      // 경로가 없으면 최소 정보만으로 UnifiedData 구성
      return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
    }

    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.csv') {
      final text = await file.readAsString();
      final series = _parseCsvToSeries(text);
      return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
    } else if (ext == '.json') {
      final text = await file.readAsString();
      // json 파싱은 상위 로직/서비스에서 해도 되지만, 여기서 바로 넣어도 OK
      return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: _safeDecodeJson(text));
    } else {
      // 이미지 등: 바이트 → base64 문자열만 보관(상위 Viewer 규약에 맞춤)
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: b64);
    }
  }

  List<double> _parseCsvToSeries(String csv) {
    // 아주 단순한 “한 열짜리 숫자 CSV” 파서(필요에 맞게 고도화)
    return csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).map((l) => double.tryParse(l.trim())).whereType<double>().toList(growable: false);
  }

  Map<String, dynamic> _safeDecodeJson(String text) {
    try {
      // ignore: avoid_dynamic_calls
      return (jsonDecode(text) as Map).cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

/// data_loader.dart의 조건부 import에서 호출
DataLoader createDataLoader() => IoDataLoader();
