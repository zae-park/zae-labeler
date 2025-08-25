import 'package:uuid/uuid.dart';
import 'package:meta/meta.dart'; // @immutable 쓰고 싶으면

enum DataSourceType { path, base64, objectUrl, unknown }

@immutable
class DataInfo {
  final String id; // 고유 식별자
  final String fileName; // 파일명 (경로/URL가 들어와도 OK: normalized 게터 제공)
  final String? filePath; // Native/데스크톱
  final String? base64Content; // Web (메모리 큰 데이터면 주의)
  final String? objectUrl; // Web Blob URL
  final String? mimeType; // 선택

  const DataInfo({required this.id, required this.fileName, this.filePath, this.base64Content, this.objectUrl, this.mimeType});

  factory DataInfo.create({required String fileName, String? filePath, String? base64Content, String? objectUrl, String? mimeType, String? id}) {
    return DataInfo(
        id: id ?? const Uuid().v4(), fileName: fileName, filePath: filePath, base64Content: base64Content, objectUrl: objectUrl, mimeType: mimeType);
  }

  /// 자주 쓰는 축약 팩토리
  factory DataInfo.fromPath(String path, {String? mimeType, String? id}) {
    final name = _extractFileName(path);
    return DataInfo.create(fileName: name, filePath: path, mimeType: mimeType, id: id);
  }

  factory DataInfo.fromBase64(String fileName, String base64, {String? mimeType, String? id}) =>
      DataInfo.create(fileName: fileName, base64Content: base64, mimeType: mimeType, id: id);

  factory DataInfo.fromObjectUrl(String fileName, String url, {String? mimeType, String? id}) =>
      DataInfo.create(fileName: fileName, objectUrl: url, mimeType: mimeType, id: id);

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

  /// 명시적으로 null로 지우고 싶을 때
  DataInfo copyWithClear({bool clearFilePath = false, bool clearBase64 = false, bool clearObjectUrl = false}) {
    return DataInfo(
      id: id,
      fileName: fileName,
      filePath: clearFilePath ? null : filePath,
      base64Content: clearBase64 ? null : base64Content,
      objectUrl: clearObjectUrl ? null : objectUrl,
      mimeType: mimeType,
    );
  }

  /// (선택) 값 객체 동등성
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DataInfo &&
            other.id == id &&
            other.fileName == fileName &&
            other.filePath == filePath &&
            other.base64Content == base64Content &&
            other.objectUrl == objectUrl &&
            other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(id, fileName, filePath, base64Content, objectUrl, mimeType);

  /// 직렬화
  factory DataInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fileName = json['fileName'];
    if (id is! String || id.isEmpty) throw ArgumentError('DataInfo.fromJson: invalid or missing "id".');

    if (fileName is! String || fileName.isEmpty) throw ArgumentError('DataInfo.fromJson: invalid or missing "fileName".');

    return DataInfo(
      id: id,
      fileName: fileName,
      base64Content: json['base64Content'] as String?,
      filePath: json['filePath'] as String?,
      objectUrl: json['objectUrl'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'fileName': fileName, 'base64Content': base64Content, 'filePath': filePath, 'objectUrl': objectUrl, 'mimeType': mimeType};

  // ---------- 편의 게터 ----------

  DataSourceType get sourceType {
    if (filePath != null && filePath!.isNotEmpty) return DataSourceType.path;
    if (base64Content != null && base64Content!.isNotEmpty) return DataSourceType.base64;
    if (objectUrl != null && objectUrl!.isNotEmpty) return DataSourceType.objectUrl;
    return DataSourceType.unknown;
  }

  bool get isWebLike => sourceType == DataSourceType.base64 || sourceType == DataSourceType.objectUrl;
  bool get isNativeLike => sourceType == DataSourceType.path;

  /// 경로/URL/쿼리 문자열이 들어와도 파일명만 추출
  String get normalizedFileName => _extractFileName(fileName);

  String get extension {
    final n = normalizedFileName;
    final dot = n.lastIndexOf('.');
    if (dot < 0 || dot == n.length - 1) return '';
    return n.substring(dot + 1).toLowerCase();
  }

  @override
  String toString() => 'DataInfo(id=$id, fileName=$fileName, src=$sourceType, mime=$mimeType)';
}

// --------- 내부 유틸 ---------

String _extractFileName(String input) {
  var s = input.trim();
  final q = s.indexOf('?');
  if (q >= 0) s = s.substring(0, q);
  final h = s.indexOf('#');
  if (h >= 0) s = s.substring(0, h);
  final slash = s.lastIndexOf(RegExp(r'[\\/]+'));
  if (slash >= 0) s = s.substring(slash + 1);
  return s;
}
