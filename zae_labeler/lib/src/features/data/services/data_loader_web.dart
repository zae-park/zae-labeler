// lib/src/features/data/services/data_loader_web.dart
import 'package:flutter/material.dart';
import 'dart:convert' show base64Decode, utf8;
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
          // CSV: base64 → utf8 텍스트
          final csvText = utf8.decode(base64Decode(b64));
          return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: _parseCsvToSeries(csvText));
        case FileType.object:
          // JSON: base64 → utf8 텍스트 → UnifiedData.objectData는 파서가 맵으로 다루는 곳도 있지만
          // 여기선 텍스트를 바로 넣지 못하므로 최소 타입 세팅 또는 필요시 jsonDecode로 Map 생성
          final jsonText = utf8.decode(base64Decode(b64));
          // 가벼운 파싱 (에러 무시)
          try {
            return UnifiedData(
                dataInfo: info,
                fileType: FileType.object,
                objectData: jsonText.isEmpty ? null : (jsonText.trim().isEmpty ? null : (jsonDecode(jsonText) as Map?)));
          } catch (_) {
            return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: null);
          }
        case FileType.unsupported:
          return UnifiedData(dataInfo: info, fileType: FileType.unsupported);
      }
    }

    // 경로가 없으면 기존처럼 타입만 식별하고 리턴(Null 가드: 뷰어에서 처리)
    if (path == null || path.isEmpty) {
      return UnifiedData(dataInfo: info, fileType: type);
    }

    try {
      if (type == FileType.object) {
        final map = await _cloud.readJsonAt(path);
        return UnifiedData(dataInfo: info, fileType: FileType.object, objectData: map);
      } else if (type == FileType.series) {
        final text = await _cloud.readTextAt(path);
        final series = _parseCsvToSeries(text);
        return UnifiedData(dataInfo: info, fileType: FileType.series, seriesData: series);
      } else if (type == FileType.image) {
        // 이미지 등 바이너리
        final b64 = await _cloud.readImageBase64At(path);
        return UnifiedData(dataInfo: info, fileType: FileType.image, imageBase64: b64);
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
