// lib/src/features/data/services/data_loader_web.dart
import 'package:flutter/material.dart';
import 'dart:convert' show base64Decode, utf8, jsonDecode;
import 'package:path/path.dart' as p;

import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/platform_helpers/storage/cloud_storage_helper.dart';

import 'data_loader_interface.dart';

class WebDataLoader implements DataLoader {
  final CloudStorageHelper _cloud;

  WebDataLoader({CloudStorageHelper? cloud}) : _cloud = cloud ?? CloudStorageHelper();

  FileType _inferType(DataInfo info) {
    final mime = (info.mimeType ?? '').toLowerCase();
    final ext = p.extension(info.fileName).toLowerCase();
    if (mime.startsWith('image/') || ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'].contains(ext)) {
      return FileType.image;
    }
    if (mime == 'text/csv' || ext == '.csv') return FileType.series;
    if (mime == 'application/json' || ext == '.json') return FileType.object;
    return FileType.unsupported;
  }

  // data:<mime>;base64,XXXX → XXXX 만 추출
  String _stripDataUrl(String s) {
    final i = s.indexOf(',');
    return s.startsWith('data:') && i != -1 ? s.substring(i + 1) : s;
  }

  Map<String, dynamic>? _safeParseJson(String text) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map) {
        return (parsed).cast<String, dynamic>();
      } else if (parsed is List) {
        return {'_root': parsed};
      } else {
        return {'_value': parsed};
      }
    } catch (e) {
      debugPrint('[WebDataLoader] json parse error: $e');
      return null;
    }
  }

  List<double>? _parseCsvToSeries(String? text) {
    if (text == null || text.isEmpty) return null;
    return text
        .split(RegExp(r'[\r\n]+'))
        .expand((line) => line.split(','))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s))
        .whereType<double>()
        .toList();
  }

  @override
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    final type = _inferType(info);
    debugPrint(
      '[WebLoader] file=${info.fileName} mime=${info.mimeType} ext=${p.extension(info.fileName)} '
      'type=$type path=${info.filePath} hasB64=${(info.base64Content?.isNotEmpty ?? false)}',
    );

    final path = info.filePath?.trim();
    final b64 = info.base64Content?.trim();

    // 0) base64 우선
    if (b64 != null && b64.isNotEmpty) {
      switch (type) {
        case FileType.image:
          {
            final raw = _stripDataUrl(b64);
            return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: raw);
          }
        case FileType.series:
          {
            final raw = _stripDataUrl(b64);
            final csvText = utf8.decode(base64Decode(raw));
            final series = _parseCsvToSeries(csvText) ?? <double>[];
            return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
          }
        case FileType.object:
          {
            final raw = _stripDataUrl(b64);
            final jsonText = utf8.decode(base64Decode(raw));
            final map = _safeParseJson(jsonText) ?? <String, dynamic>{};
            return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map);
          }
        case FileType.unsupported:
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    }

    // 1) 경로/캐시 모두 없음 → 타입 유지 + '빈 payload' 폴백
    if (path == null || path.isEmpty) {
      switch (type) {
        case FileType.object:
          debugPrint('[WebLoader] no path/base64 → object EMPTY {}');
          return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: <String, dynamic>{});
        case FileType.series:
          debugPrint('[WebLoader] no path/base64 → series EMPTY []');
          return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: <double>[]);
        case FileType.image:
          debugPrint('[WebLoader] no path/base64 → image EMPTY ""');
          return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: '');
        case FileType.unsupported:
          debugPrint('[WebLoader] no path/base64 → unsupported');
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    }

    // 2) 클라우드/네트워크 로드
    try {
      switch (type) {
        case FileType.object:
          {
            final map = await _cloud.readJsonAt(path);
            return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map ?? <String, dynamic>{});
          }
        case FileType.series:
          {
            final text = await _cloud.readTextAt(path);
            final series = _parseCsvToSeries(text) ?? <double>[];
            return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
          }
        case FileType.image:
          {
            final imgB64 = await _cloud.readImageBase64At(path) ?? '';
            return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: imgB64);
          }
        case FileType.unsupported:
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    } catch (e) {
      debugPrint('[WebDataLoader.fromDataInfo] $path load failed: $e');
      // 실패 시에도 타입 유지 + '빈 payload' 폴백
      switch (type) {
        case FileType.object:
          debugPrint('[WebLoader] fallback after error → object EMPTY {}');
          return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: <String, dynamic>{});
        case FileType.series:
          debugPrint('[WebLoader] fallback after error → series EMPTY []');
          return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: <double>[]);
        case FileType.image:
          debugPrint('[WebLoader] fallback after error → image EMPTY ""');
          return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: '');
        case FileType.unsupported:
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    }
  }
}

/// data_loader.dart의 조건부 import에서 호출
DataLoader createDataLoader() => WebDataLoader();
