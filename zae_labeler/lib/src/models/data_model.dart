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
