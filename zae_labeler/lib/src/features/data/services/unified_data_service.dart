import '../../../core/models/data/file_type.dart';
import '../../../core/models/data/data_info.dart';
import '../../../core/models/data/unified_data.dart';

import 'data_loader.dart';
import 'data_parser.dart';

/// UnifiedData 관련 유틸을 한 곳으로 모은 파사드.
/// (기존 UnifiedData.fromDataInfo / fromDataId / toDataInfo 대체)
class UnifiedDataService {
  final DataParser parser;
  final loader = createDataLoader();

  UnifiedDataService({DataParser? parser}) : parser = parser ?? DefaultDataParser();

  /// ✅ 기존: UnifiedData.fromDataInfo(dataInfo)
  Future<UnifiedData> fromDataInfo(DataInfo info) async {
    final type = FileTypeX.fromFilename(info.fileName);
    final raw = await loader.loadRaw(info);
    return parser.parse(info: info, type: type, raw: raw);
  }

  /// ✅ 기존: UnifiedData.fromDataId(dataInfos: list, dataId: id)
  Future<UnifiedData> fromDataId(List<DataInfo> dataInfos, String dataId) async {
    final info = dataInfos.firstWhere((e) => e.id == dataId, orElse: () => throw StateError('dataId not found: $dataId'));
    return fromDataInfo(info);
  }

  /// ✅ 기존: unified.toDataInfo()
  ///
  /// 기본적으로는 원본 DataInfo를 그대로 돌려보내는 게 안전합니다.
  /// (필요 시 imageBase64 등을 반영하여 덮어쓸 수 있도록 옵션 제공)
  DataInfo toDataInfo(UnifiedData u, {String? overrideFilePath, String? overrideBase64}) {
    return u.dataInfo.copyWith(
      filePath: overrideFilePath ?? u.dataInfo.filePath,
      base64Content: overrideBase64 ?? u.imageBase64 ?? u.dataInfo.base64Content,
    );
  }

  /// (선택) 빈 데이터 팩토리
  UnifiedData empty() => UnifiedData(
        dataInfo: DataInfo.create(fileName: 'empty'),
        fileType: FileType.unsupported,
      );
}
