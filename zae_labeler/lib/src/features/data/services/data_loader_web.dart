// lib/src/features/data/services/data_loader_web.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
// 웹에선 File I/O가 없으므로 네트워크/메모리 소스만 다룬다고 가정

import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/platform_helpers/storage/cloud_storage_helper.dart';

import 'data_loader_interface.dart';

class WebDataLoader implements DataLoader {
  final CloudStorageHelper _cloud;

  WebDataLoader({CloudStorageHelper? cloud}) : _cloud = cloud ?? CloudStorageHelper();

  @override
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    final ext = p.extension(info.fileName).toLowerCase();
    final path = info.filePath; // Firebase Storage 경로라고 가정 (예: users/{uid}/... 또는 커스텀)

    // 경로가 없으면 기존처럼 타입만 식별하고 리턴(Null 가드: 뷰어에서 처리)
    if (path == null || path.isEmpty) {
      if (ext == '.csv') return UnifiedData(dataInfo: info, fileType: FileType.series);
      if (ext == '.json') return UnifiedData(dataInfo: info, fileType: FileType.object);
      return UnifiedData(dataInfo: info, fileType: FileType.image);
    }

    try {
      if (ext == '.json') {
        final map = await _cloud.readJsonAt(path);
        return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map);
      } else if (ext == '.csv') {
        final text = await _cloud.readTextAt(path);
        final series = _parseCsvToSeries(text);
        return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
      } else {
        // 이미지 등 바이너리
        final b64 = await _cloud.readImageBase64At(path);
        return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: b64);
      }
    } catch (e) {
      debugPrint("[WebDataLoader.fromDataInfo] $path 로딩 실패: $e");
      // 실패 시 타입만 세팅된 최소 객체 반환(뷰어에서 '비어있음' 처리)
      if (ext == '.json') return UnifiedData(dataInfo: info, fileType: FileType.object);
      if (ext == '.csv') return UnifiedData(dataInfo: info, fileType: FileType.series);
      return UnifiedData(dataInfo: info, fileType: FileType.image);
    }
  }

  List<double>? _parseCsvToSeries(String? text) {
    if (text == null || text.isEmpty) return null;
    // 아주 단순한 파서(필요시 교체)
    return text
        .split(RegExp(r'[\r\n]+'))
        .expand((line) => line.split(','))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s))
        .whereType<double>()
        .toList();
  }
}

/// data_loader.dart의 조건부 import에서 호출
DataLoader createDataLoader() => WebDataLoader();
