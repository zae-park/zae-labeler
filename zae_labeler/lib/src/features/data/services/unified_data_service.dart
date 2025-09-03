// lib/src/features/data/services/unified_data_service.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';

import 'data_loader.dart';
import 'data_loader_interface.dart';

/// IO/파싱을 캡슐화한 상위 서비스
class UnifiedDataService {
  final DataLoader _loader = createDataLoader();

  Future<UnifiedData> fromDataInfo(DataInfo info) {
    debugPrint('[UniDataService] id=${info.id} name=${info.fileName} path=${info.filePath} mime=${info.mimeType}');
    // 경로/캐시가 전혀 없으면 바로 unsupported로 (웹 재접속/캐시 미존재 방어)
    final hasContent = (info.filePath?.isNotEmpty ?? false) || (info.base64Content?.isNotEmpty ?? false) || (info.objectUrl?.isNotEmpty ?? false);
    // if (!hasContent) return Future.value(UnifiedData(dataInfo: info, fileType: FileType.unsupported));
    if (!hasContent) debugPrint('[UniDataService] \t\t no content → delegate to loader for fallback');
    return _loader.fromDataInfo(info);
  }

  /// 빈 데이터(플레이스홀더) 필요 시
  UnifiedData empty() {
    // 프로젝트에 맞게 조정
    return UnifiedData(
      dataInfo: DataInfo.create(fileName: 'untitled'),
      fileType: FileType.unsupported,
    );
  }
}
