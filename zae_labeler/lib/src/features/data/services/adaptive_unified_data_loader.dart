// lib/src/features/data/services/adaptive_unified_data_loader.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

/// 프로젝트의 DataInfo들을 실제 콘텐츠가 담긴 UnifiedData로 변환합니다.
/// - ❌ 라벨/상태 계산 없음 (순수 IO/파싱만)
/// - ✅ 상태가 필요하면 build_data_with_status.dart를 사용하세요.
Future<List<UnifiedData>> loadDataAdaptively(Project project, StorageHelperInterface storageHelper) {
  final loader = AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);
  return loader.load(project);
}

class AdaptiveUnifiedDataLoader {
  final UnifiedDataService uds;
  final StorageHelperInterface storage;

  AdaptiveUnifiedDataLoader({required this.uds, required this.storage});

  /// 데이터 1건을 읽어 파싱합니다. (라벨링 화면의 지연 로딩용)
  Future<UnifiedData> loadOne(DataInfo info) => uds.fromDataInfo(info);

  /// Project.dataInfos를 순회하여 UnifiedData로 파싱합니다. (전체를 한 번에 읽으므로 대량 데이터에는 [loadOne]을 쓰세요)
  /// dataInfos가 비어 있으면 placeholder 1개를 돌려줍니다.
  Future<List<UnifiedData>> load(Project project) async {
    if (project.dataInfos.isEmpty) {
      debugPrint("⚠️ [AdaptiveLoader] No dataInfos → returning placeholder");
      return [uds.empty()];
    }

    final futures = project.dataInfos.map((info) => uds.fromDataInfo(info));
    final list = await Future.wait(futures);
    return list.isEmpty ? [uds.empty()] : list;
  }
}
