// lib/src/models/data_model.dart

/*
이 파일은 데이터 모델을 정의하며, 다양한 데이터 유형(시계열, JSON 오브젝트, 이미지 등)을 다루기 위한 클래스들을 포함합니다.
FileData, DataPath, UnifiedData 클래스를 사용하여 데이터를 로드, 변환, 직렬화 및 관리할 수 있습니다.
*/

import 'dart:convert';
import 'dart:io';

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
  final String fileName; // 파일 이름
  final String? base64Content; // Base64 인코딩된 파일 내용 (Web 환경)
  final String? filePath; // 파일 경로 (Native 환경)

  DataPath({required this.fileName, this.base64Content, this.filePath});

  /// Loads the content of the file based on its environment (Web or Native).
  Future<String?> loadData() async {
    if (base64Content != null) {
      // Web 환경: Base64 디코딩
      return utf8.decode(base64Decode(base64Content!));
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
        fileName: json['fileName'],
        base64Content: json['base64Content'],
        filePath: json['filePath'],
      );

  /// Converts the DataPath instance into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'base64Content': base64Content,
        'filePath': filePath,
      };
}

/// Represents unified data that encapsulates various types of content.
class UnifiedData {
  final File? file; // Native 환경의 파일 객체
  final List<double>? seriesData; // 시계열 데이터
  final Map<String, dynamic>? objectData; // JSON 오브젝트 데이터
  final String? content; // ✅ Base64 인코딩된 이미지 데이터 추가 (Web 지원)
  final FileType fileType; // 파일 유형

  UnifiedData({
    this.file,
    this.seriesData,
    this.objectData,
    this.content,
    required this.fileType,
  });

  factory UnifiedData.empty() => UnifiedData(fileType: FileType.unsupported);

  /// Creates a UnifiedData instance from a DataPath by determining the file type.
  static Future<UnifiedData> fromDataPath(DataPath dataPath) async {
    final fileName = dataPath.fileName;
    if (fileName.endsWith('.csv')) {
      // 시계열 데이터 로드
      final content = await dataPath.loadData();
      final seriesData = _parseSeriesData(content ?? '');
      return UnifiedData(seriesData: seriesData, fileType: FileType.series);
    } else if (fileName.endsWith('.json')) {
      // JSON 오브젝트 데이터 로드
      final content = await dataPath.loadData();
      final objectData = _parseObjectData(content ?? '');
      return UnifiedData(objectData: objectData, fileType: FileType.object);
    } else if (['.png', '.jpg', '.jpeg'].any((ext) => fileName.endsWith(ext))) {
      // 이미지 파일 로드
      final content = await dataPath.loadData();
      return UnifiedData(file: dataPath.filePath != null ? File(dataPath.filePath!) : null, content: content, fileType: FileType.image);
    }

    // 지원되지 않는 파일 형식
    return UnifiedData(fileType: FileType.unsupported);
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
