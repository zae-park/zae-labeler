// lib/src/features/data/services/unified_data_service.dart
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

import 'data_loader.dart';
import 'data_loader_interface.dart';

/// IO/파싱을 캡슐화한 상위 서비스
class UnifiedDataService {
  final DataLoader _loader = createDataLoader();

  Future<UnifiedData> fromDataInfo(DataInfo info) {
    // 필요시 여기서 추가 전처리/후처리(파싱 규칙 등)를 넣을 수 있습니다.
    return _loader.fromDataInfo(info);
  }

  /// 빈 데이터(플레이스홀더) 필요 시
  UnifiedData empty() {
    // 프로젝트에 맞게 조정
    return UnifiedData(dataInfo: DataInfo.create(fileName: 'untitled'), fileType: FileType.unsupported);
  }
}
