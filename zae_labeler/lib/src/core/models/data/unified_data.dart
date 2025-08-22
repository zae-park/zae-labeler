import 'file_type.dart';
import 'data_info.dart';

/// 파싱 결과를 담는 순수 컨테이너.
/// - IO/디코딩/파일 핸들 없음
/// - 라벨 상태 등 라벨 도메인은 *여기서 다루지 않음*
class UnifiedData {
  final DataInfo dataInfo;
  final FileType fileType;

  /// 시계열 데이터 (csv 파싱 결과)
  final List<double>? seriesData;

  /// JSON 오브젝트 데이터
  final Map<String, dynamic>? objectData;

  /// 이미지: base64 또는 URI 등 상위 레이어 규칙에 맞춘 원문
  /// (여기서는 문자열로만 보관)
  final String? imageBase64;

  const UnifiedData({required this.dataInfo, required this.fileType, this.seriesData, this.objectData, this.imageBase64});

  String get dataId => dataInfo.id;
  String get fileName => dataInfo.fileName;

  UnifiedData copyWith({DataInfo? dataInfo, FileType? fileType, List<double>? seriesData, Map<String, dynamic>? objectData, String? imageBase64}) {
    return UnifiedData(
      dataInfo: dataInfo ?? this.dataInfo,
      fileType: fileType ?? this.fileType,
      seriesData: seriesData ?? this.seriesData,
      objectData: objectData ?? this.objectData,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  /// 직렬화(선택): 필요하면 저장소 캐시에 보관할 수 있음
  Map<String, dynamic> toJson() => {
        'dataInfo': dataInfo.toJson(),
        'fileType': fileType.name,
        'seriesData': seriesData,
        'objectData': objectData,
        'imageBase64': imageBase64,
      };

  factory UnifiedData.fromJson(Map<String, dynamic> json) {
    final info = DataInfo.fromJson(json['dataInfo'] as Map<String, dynamic>);
    final typeName = json['fileType'] as String? ?? 'unsupported';
    final type = FileType.values.firstWhere((e) => e.name == typeName, orElse: () => FileType.unsupported);
    return UnifiedData(
      dataInfo: info,
      fileType: type,
      seriesData: (json['seriesData'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      objectData: json['objectData'] as Map<String, dynamic>?,
      imageBase64: json['imageBase64'] as String?,
    );
  }
}
