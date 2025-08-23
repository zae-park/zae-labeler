import 'package:uuid/uuid.dart';

/// 원본 데이터의 위치/메타 정보 (웹/네이티브 공용).
/// *순수 값 객체*: IO/디코딩 로직 없음.
class DataInfo {
  final String id; // 고유 식별자 (항상 필요)
  final String fileName; // 파일명 (항상 필요)
  final String? filePath; // Native/데스크톱
  final String? base64Content; // Web
  final String? objectUrl; // Web Blob URL
  final String? mimeType; // 선택

  const DataInfo({required this.id, required this.fileName, this.filePath, this.base64Content, this.objectUrl, this.mimeType});

  factory DataInfo.create({required String fileName, String? filePath, String? base64Content, String? objectUrl, String? mimeType}) {
    return DataInfo(id: const Uuid().v4(), fileName: fileName, filePath: filePath, base64Content: base64Content, objectUrl: objectUrl, mimeType: mimeType);
  }

  DataInfo copyWith({String? id, String? fileName, String? filePath, String? base64Content, String? objectUrl, String? mimeType}) {
    return DataInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      base64Content: base64Content ?? this.base64Content,
      objectUrl: objectUrl ?? this.objectUrl,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  factory DataInfo.fromJson(Map<String, dynamic> json) => DataInfo(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        base64Content: json['base64Content'] as String?,
        filePath: json['filePath'] as String?,
        objectUrl: json['objectUrl'] as String?,
        mimeType: json['mimeType'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'fileName': fileName, 'base64Content': base64Content, 'filePath': filePath, 'objectUrl': objectUrl, 'mimeType': mimeType};
}
