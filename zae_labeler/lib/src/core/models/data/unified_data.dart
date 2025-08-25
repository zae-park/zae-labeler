import 'dart:collection';
import 'file_type.dart';
import 'data_info.dart';

class UnifiedData {
  final DataInfo dataInfo;
  final FileType fileType;

  final UnmodifiableListView<double>? seriesData;
  final UnmodifiableMapView<String, dynamic>? objectData;
  final String? imageBase64;

  const UnifiedData._({required this.dataInfo, required this.fileType, this.seriesData, this.objectData, this.imageBase64});

  /// 타입별 편의 팩토리
  factory UnifiedData.fromSeries({required DataInfo info, required List<double> values}) {
    _requireOnlySeries(values);
    return UnifiedData._(dataInfo: info, fileType: FileType.series, seriesData: UnmodifiableListView(values));
  }

  factory UnifiedData.fromObject({required DataInfo info, required Map<String, dynamic> object}) {
    _requireOnlyObject(object);
    return UnifiedData._(dataInfo: info, fileType: FileType.object, objectData: UnmodifiableMapView(object));
  }

  factory UnifiedData.fromImageBase64({required DataInfo info, required String base64}) {
    _requireOnlyImage(base64);
    return UnifiedData._(dataInfo: info, fileType: FileType.image, imageBase64: base64);
  }

  /// 범용 생성 (기존 시그니처 호환)
  factory UnifiedData(
      {required DataInfo dataInfo, required FileType fileType, List<double>? seriesData, Map<String, dynamic>? objectData, String? imageBase64}) {
    _validatePayload(fileType, seriesData, objectData, imageBase64);
    return UnifiedData._(
      dataInfo: dataInfo,
      fileType: fileType,
      seriesData: seriesData == null ? null : UnmodifiableListView(seriesData),
      objectData: objectData == null ? null : UnmodifiableMapView(objectData),
      imageBase64: imageBase64,
    );
  }

  String get dataId => dataInfo.id;
  String get fileName => dataInfo.fileName;

  bool get hasSeries => seriesData != null;
  bool get hasObject => objectData != null;
  bool get hasImage => imageBase64 != null;

  /// 선택: kind 헬퍼
  String get kind => switch (fileType) { FileType.series => 'series', FileType.object => 'object', FileType.image => 'image', _ => 'unsupported' };

  UnifiedData copyWith({DataInfo? dataInfo, FileType? fileType, List<double>? seriesData, Map<String, dynamic>? objectData, String? imageBase64}) {
    final nextType = fileType ?? this.fileType;
    final nextSeries = seriesData ?? this.seriesData;
    final nextObject = objectData ?? this.objectData;
    final nextImage = imageBase64 ?? this.imageBase64;
    _validatePayload(nextType, nextSeries is List<double> ? nextSeries : (nextSeries as UnmodifiableListView<double>?),
        nextObject is Map<String, dynamic> ? nextObject : (nextObject as UnmodifiableMapView<String, dynamic>?), nextImage);

    return UnifiedData._(
      dataInfo: dataInfo ?? this.dataInfo,
      fileType: nextType,
      seriesData: switch (nextSeries) { null => null, UnmodifiableListView<double> v => v, List<double> v => UnmodifiableListView(v), _ => this.seriesData },
      objectData: switch (nextObject) {
        null => null,
        UnmodifiableMapView<String, dynamic> v => v,
        Map<String, dynamic> v => UnmodifiableMapView(v),
        _ => this.objectData,
      },
      imageBase64: nextImage,
    );
  }

  Map<String, dynamic> toJson() => {
        'dataInfo': dataInfo.toJson(),
        'fileType': fileType.name,
        'seriesData': seriesData?.toList(),
        'objectData': objectData == null ? null : Map<String, dynamic>.from(objectData!),
        'imageBase64': imageBase64,
      };

  factory UnifiedData.fromJson(Map<String, dynamic> json) {
    final info = DataInfo.fromJson(json['dataInfo'] as Map<String, dynamic>);
    final typeName = (json['fileType'] as String?) ?? 'unsupported';
    final type = FileType.values.firstWhere((e) => e.name == typeName, orElse: () => FileType.unsupported);

    final rawSeries = (json['seriesData'] as List?)?.map((e) => (e as num).toDouble()).toList();
    final rawObject = json['objectData'] as Map<String, dynamic>?;
    final rawImage = json['imageBase64'] as String?;

    _validatePayload(type, rawSeries, rawObject, rawImage);

    return UnifiedData._(
      dataInfo: info,
      fileType: type,
      seriesData: rawSeries == null ? null : UnmodifiableListView(rawSeries),
      objectData: rawObject == null ? null : UnmodifiableMapView(rawObject),
      imageBase64: rawImage,
    );
  }

  // 값 객체 비교 (필요하면 equatable 사용)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedData &&
          other.dataInfo == dataInfo &&
          other.fileType == fileType &&
          _listEquals(other.seriesData, seriesData) &&
          _mapEquals(other.objectData, objectData) &&
          other.imageBase64 == imageBase64;

  @override
  int get hashCode => Object.hash(dataInfo, fileType, seriesData == null ? 0 : Object.hashAll(seriesData!),
      objectData == null ? 0 : Object.hashAll(objectData!.entries.map((e) => Object.hash(e.key, e.value))), imageBase64);

  @override
  String toString() => 'UnifiedData($kind, id=${dataInfo.id}, file=${dataInfo.fileName})';
}

// ---------- 내부 유효성/헬퍼 ----------

void _validatePayload(FileType t, List<double>? series, Map<String, dynamic>? object, String? image) {
  final nonNull = [series, object, image].where((e) => e != null).length;
  if (t == FileType.unsupported) {
    if (nonNull != 0) throw ArgumentError('Unsupported fileType must not carry payload.');
    return;
  }
  switch (t) {
    case FileType.series:
      if (series == null || object != null || image != null) throw ArgumentError('series type requires only seriesData.');
      // NaN/Infinity 보호 (선택)
      if (series.any((v) => v.isNaN || v.isInfinite)) throw ArgumentError('seriesData contains NaN/Infinity.');

      break;
    case FileType.object:
      if (object == null || series != null || image != null) throw ArgumentError('object type requires only objectData.');
      break;
    case FileType.image:
      if (image == null || series != null || object != null) throw ArgumentError('image type requires only imageBase64.');
      break;
    case FileType.unsupported:
      // 위에서 처리됨
      break;
  }
}

void _requireOnlySeries(List<double>? v) {
  if (v == null) throw ArgumentError('seriesData is required.');
  if (v.any((x) => x.isNaN || x.isInfinite)) throw ArgumentError('seriesData contains NaN/Infinity.');
}

void _requireOnlyObject(Map<String, dynamic>? v) {
  if (v == null) throw ArgumentError('objectData is required.');
}

void _requireOnlyImage(String? v) {
  if (v == null || v.isEmpty) throw ArgumentError('imageBase64 is required.');
}

bool _listEquals(List<double>? a, List<double>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key)) return false;
    if (b[e.key] != e.value) return false;
  }
  return true;
}
