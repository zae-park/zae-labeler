import 'package:uuid/uuid.dart';

/// 원본 데이터의 위치/메타 정보 (웹/네이티브 공용).
/// *순수 값 객체*: IO/디코딩 로직 없음.
class DataInfo {
  final String id; // 고유 식별자
  final String fileName; // 파일명 (확장자 포함)
  final String? base64Content; // Web: base64 인코딩 원본(옵션)
  final String? filePath; // Native: 파일 경로(옵션)

  const DataInfo({required this.id, required this.fileName, this.base64Content, this.filePath});

  /// 새 DataInfo를 생성할 때 편의 ID 발급자
  factory DataInfo.create({required String fileName, String? base64Content, String? filePath}) {
    return DataInfo(id: const Uuid().v4(), fileName: fileName, base64Content: base64Content, filePath: filePath);
  }

  DataInfo copyWith({String? id, String? fileName, String? base64Content, String? filePath}) {
    return DataInfo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      base64Content: base64Content ?? this.base64Content,
      filePath: filePath ?? this.filePath,
    );
  }

  factory DataInfo.fromJson(Map<String, dynamic> json) => DataInfo(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        base64Content: json['base64Content'] as String?,
        filePath: json['filePath'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'fileName': fileName, 'base64Content': base64Content, 'filePath': filePath};
}
