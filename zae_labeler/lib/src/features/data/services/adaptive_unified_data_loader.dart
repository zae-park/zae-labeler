// lib/src/features/data/services/adaptive_unified_data_loader.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/data/models/data_with_status.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';

// (선택) 기존 스타일의 함수형 API 유지용
Future<List<DataWithStatus>> loadDataAdaptively(Project project, StorageHelperInterface storageHelper) {
  final loader = AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);
  return loader.load(project);
}

/// 프로젝트 단위로 UnifiedData들을 로드하고,
/// 저장소에 있는 라벨 유무를 기반으로 LabelStatus를 합성합니다.
/// IO/파싱은 UnifiedDataService가 담당합니다.
class AdaptiveUnifiedDataLoader {
  final UnifiedDataService uds;
  final StorageHelperInterface storage;

  AdaptiveUnifiedDataLoader({required this.uds, required this.storage});

  /// 프로젝트의 dataInfos를 순회하면서:
  /// 1) UnifiedDataService로 데이터 파싱
  /// 2) 라벨 저장소에서 dataId별 라벨 존재 확인
  /// 3) DataWithStatus(data, status)로 묶어 반환
  Future<List<DataWithStatus>> load(Project project) async {
    // 0) 라벨 맵(있으면 complete, 없으면 incomplete)
    final labels = await _safeLoadLabels(project.id);
    final labelMap = {for (final l in labels) l.dataId: l};

    // 1) dataInfos가 없으면 placeholder 반환(기존 동작 유지)
    if (project.dataInfos.isEmpty) {
      debugPrint("⚠️ [AdaptiveLoader] No dataInfos → returning placeholder");
      final placeholder = DataInfo.create(fileName: 'untitled');
      final u = await uds.fromDataInfo(placeholder);
      return [DataWithStatus(data: u, status: LabelStatus.incomplete)];
    }

    // 2) dataInfos → UnifiedData → status 합성`
    final futures = project.dataInfos.map((info) async {
      final u = await uds.fromDataInfo(info);
      final labeled = labelMap[info.id]?.isLabeled == true;
      final status = labeled ? LabelStatus.complete : LabelStatus.incomplete;
      return DataWithStatus(data: u, status: status);
    });

    final list = await Future.wait(futures);
    return list.isEmpty ? [DataWithStatus(data: uds.empty(), status: LabelStatus.incomplete)] : list;
  }

  Future<List<LabelModel>> _safeLoadLabels(String projectId) async {
    try {
      return await storage.loadAllLabelModels(projectId);
    } catch (e) {
      debugPrint("❌ [AdaptiveLoader] Failed to load label models for projectId=$projectId : $e");
      return const <LabelModel>[];
    }
  }
}
