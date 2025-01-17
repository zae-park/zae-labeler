// lib/src/models/data_model.dart
import 'dart:convert';
import 'dart:io';

enum FileType { series, object, image, unsupported }

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

class DataPath {
  final String fileName;
  final String? base64Content; // Web 환경
  final String? filePath; // Native 환경

  DataPath({required this.fileName, this.base64Content, this.filePath});

  // 데이터 로드
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

  // JSON 직렬화 및 역직렬화
  factory DataPath.fromJson(Map<String, dynamic> json) => DataPath(
        fileName: json['fileName'],
        base64Content: json['base64Content'],
        filePath: json['filePath'],
      );

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'base64Content': base64Content,
        'filePath': filePath,
      };
}

class UnifiedData {
  final File? file; // Native 환경의 파일 객체
  final List<double>? seriesData; // 시계열 데이터
  final Map<String, dynamic>? objectData; // JSON 오브젝트 데이터
  final FileType fileType; // 파일 유형

  UnifiedData({
    this.file,
    this.seriesData,
    this.objectData,
    required this.fileType,
  });

  // 데이터 로드 메서드
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
      final file = dataPath.filePath != null ? File(dataPath.filePath!) : null;
      return UnifiedData(file: file, fileType: FileType.image);
    }

    // 지원되지 않는 파일 형식
    return UnifiedData(fileType: FileType.unsupported);
  }

  // 시계열 데이터 파싱
  static List<double> _parseSeriesData(String content) {
    final lines = content.split('\n');
    return lines.expand((line) => line.split(',')).map((value) => double.tryParse(value.trim()) ?? 0.0).toList();
  }

  // JSON 오브젝트 데이터 파싱
  static Map<String, dynamic> _parseObjectData(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
