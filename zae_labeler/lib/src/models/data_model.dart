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
