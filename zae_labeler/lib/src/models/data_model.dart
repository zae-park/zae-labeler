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
  final String fileName; // 파일 이름 (Web, Native 공통)
  final String? base64Content; // Web: Base64로 인코딩된 데이터
  final String? filePath; // Native: 파일 경로

  DataPath({required this.fileName, this.base64Content, this.filePath});

  // JSON 직렬화/역직렬화 지원
  factory DataPath.fromJson(Map<String, dynamic> json) {
    return DataPath(
      fileName: json['fileName'],
      base64Content: json['base64Content'],
      filePath: json['filePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'base64Content': base64Content,
      'filePath': filePath,
    };
  }
}
