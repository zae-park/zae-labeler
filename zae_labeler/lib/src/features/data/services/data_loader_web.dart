// lib/src/features/data/services/data_loader_web.dart
import 'package:flutter/material.dart';
import 'dart:convert' show base64Decode, utf8, jsonDecode;
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

  FileType _inferType(DataInfo info) {
    final mime = (info.mimeType ?? '').toLowerCase();
    final ext = p.extension(info.fileName).toLowerCase();
    if (mime.startsWith('image/') || ['.png', '.jpg', '.jpeg', '.webp'].contains(ext)) {
      return FileType.image;
    }
    if (mime == 'text/csv' || ext == '.csv') return FileType.series;
    if (mime == 'application/json' || ext == '.json') return FileType.object;
    return FileType.unsupported;
  }

  @override
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    final type = _inferType(info);
    final path = info.filePath; // Firebase Storage 경로 또는 http(s) URL

    // 0) ✅ base64 최우선 (웹에서 로컬 파일을 바로 표시)
    final b64 = info.base64Content;
    if (b64 != null && b64.isNotEmpty) {
      switch (type) {
        case FileType.image:
          // 이미지: base64 문자열 그대로 저장
          return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: b64);
        case FileType.series:
          final csvText = utf8.decode(base64Decode(b64));
          return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: _parseCsvToSeries(csvText));
        case FileType.object:
          {
            // JSON: base64 → utf8 텍스트 → jsonDecode
            final jsonText = utf8.decode(base64Decode(b64));
            Map<String, dynamic>? map;
            try {
              final parsed = jsonDecode(jsonText);
              if (parsed is Map) {
                // Map<dynamic,dynamic> → Map<String,dynamic> 안전 캐스팅
                map = (parsed).cast<String, dynamic>();
              } else if (parsed is List) {
                // 루트 배열/혼합 타입을 안전하게 감싸서 Map<String,dynamic>로 전달
                map = {'_root': parsed};
              } else {
                // 스칼라(String/num/bool/null)도 감싸서 전달
                map = {'_value': parsed};
              }
            } catch (_) {
              map = null;
            }
            return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map);
          }

        case FileType.unsupported:
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    }

    // 1) 경로가 없으면 타입만 세팅(뷰어에서 '내용 없음' 처리)
    if (path == null || path.isEmpty) {
      return UnifiedData(dataInfo: info, fileType: type);
    }

    // 2) 클라우드/네트워크 경로에서 로드
    try {
      if (type == FileType.object) {
        final map = await _cloud.readJsonAt(path);
        return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map);
      } else if (type == FileType.series) {
        final text = await _cloud.readTextAt(path);
        final series = _parseCsvToSeries(text);
        return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
      } else if (type == FileType.image) {
        final imgB64 = await _cloud.readImageBase64At(path);
        return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: imgB64);
      } else {
        return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    } catch (e) {
      debugPrint("[WebDataLoader.fromDataInfo] $path 로딩 실패: $e");
      // 실패 시 타입만 세팅된 최소 객체 반환(뷰어에서 '비어있음' 처리)
      return UnifiedData(dataInfo: info, fileType: type);
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
