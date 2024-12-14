import 'dart:io';

enum FileType { series, object, image, unsupported }

class UnifiedData {
  final File? file; // 파일
  final List<double>? seriesData; // 시계열 데이터
  final Map<String, dynamic>? objectData; // JSON 오브젝트 데이터
  final FileType fileType; // 파일 유형

  UnifiedData({this.file, this.seriesData, this.objectData, required this.fileType});
}

class FileData {
  final String name; // 파일 이름
  final String type; // 파일 타입 (e.g., 'image/png', 'application/json')
  // final FileType type;
  final String content; // 파일 내용 (base64 인코딩)
  String? path;

  FileData({this.path, required this.name, required this.type, required this.content});

  // JSON 변환 메소드
  Map<String, dynamic> toJson() => {'name': name, 'path': path, 'type': type, 'content': content};
  static FileData fromJson(Map<String, dynamic> json) => FileData(name: json['name'], path: json['path'] ?? "", type: json['type'], content: json['content']);
}
