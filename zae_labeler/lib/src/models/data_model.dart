// lib/src/models/data_model.dart

/*
이 파일은 데이터 모델을 정의하며, 다양한 데이터 유형(시계열, JSON 오브젝트, 이미지 등)을 다루기 위한 클래스들을 포함합니다.
FileData, DataPath, UnifiedData 클래스를 사용하여 데이터를 로드, 변환, 직렬화 및 관리할 수 있습니다.
*/

import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

enum FileType { series, object, image, unsupported }

/// Represents file data and its associated content and metadata.
class FileData {
  final String name; // 파일 이름
  final String type; // 파일 타입
  final String content; // Base64 인코딩된 파일 내용
  List<double>? seriesData; // 시계열 데이터
  Map<String, dynamic>? objectData; // JSON 오브젝트 데이터
  FileType? fileType; // 파일 유형

  FileData({
    required this.name,
    required this.type,
    required this.content,
    this.seriesData,
    this.objectData,
    this.fileType,
  });
}

/// Represents a data path that can be used to load file content.
class DataPath {
  final String id; // ✅ 고유 식별자 (uuid)
  final String fileName; // 파일 이름
  final String? base64Content; // Base64 인코딩된 파일 내용 (Web 환경)
  final String? filePath; // 파일 경로 (Native 환경)

  DataPath({String? id, required this.fileName, this.base64Content, this.filePath}) : id = id ?? const Uuid().v4();

  /// Loads the content of the file based on its environment (Web or Native).
  Future<String?> loadData() async {
    if (base64Content != null) {
      // ✅ 이미지 데이터는 UTF-8 디코딩 없이 그대로 반환
      if (['.png', '.jpg', '.jpeg'].any((ext) => fileName.endsWith(ext))) {
        return base64Content;
      }
      return utf8.decode(base64Decode(base64Content!)); // ✅ JSON, CSV 파일만 UTF-8 디코딩
    } else if (filePath != null) {
      // Native 환경: 파일에서 데이터 읽기
      final file = File(filePath!);
      if (file.existsSync()) {
        return await file.readAsString();
      }
    }
    return null; // 데이터가 없는 경우
  }

  /// Creates a DataPath instance from a JSON-compatible map.
  factory DataPath.fromJson(Map<String, dynamic> json) => DataPath(
        id: json['id'],
        fileName: json['fileName'],
        base64Content: json['base64Content'],
        filePath: json['filePath'],
      );

  /// Converts the DataPath instance into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'base64Content': base64Content,
        'filePath': filePath,
      };
}

/// Represents unified data that encapsulates various types of content.
class UnifiedData {
  final String dataId; // ✅ 유일 식별자 추가
  final String fileName;
  final FileType fileType; // 파일 유형
  final File? file; // Native 환경의 파일 객체
  final List<double>? seriesData; // 시계열 데이터
  final Map<String, dynamic>? objectData; // JSON 오브젝트 데이터

  final String? content; // ✅ Base64 인코딩된 이미지 데이터 추가 (Web 지원)

  UnifiedData({
    required this.dataId,
    this.file,
    this.seriesData,
    this.objectData,
    this.content,
    required this.fileName,
    required this.fileType,
  });

  factory UnifiedData.empty() => UnifiedData(dataId: 'empty', fileType: FileType.unsupported, fileName: '');

  /// Creates a UnifiedData instance from a DataPath by determining the file type.
  static Future<UnifiedData> fromDataPath(DataPath dataPath) async {
    final fileName = dataPath.fileName;
    final id = dataPath.id;

    if (fileName.endsWith('.csv')) {
      // 시계열 데이터 로드
      final content = await dataPath.loadData();
      final seriesData = _parseSeriesData(content ?? '');
      return UnifiedData(dataId: id, fileName: fileName, seriesData: seriesData, fileType: FileType.series);
    } else if (fileName.endsWith('.json')) {
      // JSON 오브젝트 데이터 로드
      final content = await dataPath.loadData();
      final objectData = _parseObjectData(content ?? '');
      return UnifiedData(dataId: id, fileName: fileName, objectData: objectData, fileType: FileType.object);
    } else if (['.png', '.jpg', '.jpeg'].any((ext) => fileName.endsWith(ext))) {
      // ✅ 이미지 파일 로드 (UTF-8 디코딩 없이 처리)
      final content = await dataPath.loadData();
      return UnifiedData(
        dataId: id,
        fileName: fileName,
        file: dataPath.filePath != null ? File(dataPath.filePath!) : null,
        content: content,
        fileType: FileType.image,
      );
    }

    // 지원되지 않는 파일 형식
    return UnifiedData(dataId: id, fileType: FileType.unsupported, fileName: fileName);
  }

  /// Parses series data (CSV format) into a list of doubles.
  static List<double> _parseSeriesData(String content) {
    final lines = content.split('\n');
    return lines.expand((line) => line.split(',')).map((value) => double.tryParse(value.trim()) ?? 0.0).toList();
  }

  /// Parses JSON object data from a string into a Map.
  static Map<String, dynamic> _parseObjectData(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
