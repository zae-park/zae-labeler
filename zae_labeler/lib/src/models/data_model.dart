import 'dart:io';

enum FileType { series, object, image, unsupported }

class UnifiedData {
  final File? file; // 파일
  final List<double>? seriesData; // 시계열 데이터
  final Map<String, dynamic>? objectData; // JSON 오브젝트 데이터
  final FileType fileType; // 파일 유형

  UnifiedData({this.file, this.seriesData, this.objectData, required this.fileType});
}
