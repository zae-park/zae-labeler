// lib/utils/adaptive/adaptive_data_loader.dart
import 'package:flutter/foundation.dart';
import '../models/project/project_model.dart';
import '../models/data/data_model.dart';
import '../../features/label/models/label_model.dart';
import '../../platform_helpers/storage/interface_storage_helper.dart';

/// {@template adaptive_data_loader}
/// 플랫폼에 따라 프로젝트의 데이터를 적절하게 불러오기 위한 어댑터 함수입니다.
///
/// ✅ 목적:
/// - `dataId`를 중심으로 모든 UnifiedData를 구성합니다.
/// - Web은 `LabelModel` 기반으로 복원하며,
/// - Native는 `project.dataInfos`를 기준으로 `dataId → filePath`를 resolve합니다.
///
/// ✅ 책임:
/// - 플랫폼에 따라 라벨 목록 또는 로컬 파일 경로에서 데이터를 적절히 구성합니다.
/// - ViewModel 등 상위 계층은 플랫폼에 관계없이 동일한 방식으로 UnifiedData를 사용할 수 있습니다.
/// {@endtemplate}
Future<List<UnifiedData>> loadDataAdaptively(Project project, StorageHelperInterface storageHelper) async {
  if (kIsWeb) {
    return await _loadFromLabels(project, storageHelper);
  } else {
    return await _loadFromPaths(project);
  }
}

/// Web: 라벨 목록 기반으로 `dataId`만 사용하여 구성
Future<List<UnifiedData>> _loadFromLabels(Project project, StorageHelperInterface storageHelper) async {
  List<LabelModel> labels = [];
  try {
    labels = await storageHelper.loadAllLabelModels(project.id);
  } catch (e) {
    debugPrint("❌ [AdaptiveLoader] Failed to load label models for projectId=${project.id} : $e");
  }

  final Map<String, LabelModel> labelMap = {
    for (var label in labels) label.dataId: label,
  };

  final allData = await Future.wait(project.dataInfos.map((info) async {
    final label = labelMap[info.id];
    final status = label?.isLabeled == true ? LabelStatus.complete : LabelStatus.incomplete;
    final data = await UnifiedData.fromDataInfo(info);
    return data.copyWith(status: status);
  }));

  if (allData.isEmpty) {
    debugPrint("⚠️ [AdaptiveLoader] No labels and no dataInfos → returning placeholder");
    final placeholderInfo = DataInfo(id: 'placeholder', fileName: 'untitled');
    final placeholderData = await UnifiedData.fromDataInfo(placeholderInfo);
    return [placeholderData.copyWith(status: LabelStatus.incomplete)];
  }

  return allData;
}

/// Native: project.dataInfos에서 dataId → filePath를 resolve하여 구성
Future<List<UnifiedData>> _loadFromPaths(Project project) async {
  if (project.dataInfos.isEmpty) {
    debugPrint("⚠️ [AdaptiveLoader] No dataInfos found → returning placeholder");
    final placeholderInfo = DataInfo(id: 'placeholder', fileName: 'untitled');
    final placeholderData = await UnifiedData.fromDataInfo(placeholderInfo);
    return [placeholderData.copyWith(status: LabelStatus.incomplete)];
  }

  return Future.wait(project.dataInfos.map((e) => UnifiedData.fromDataInfo(e)));
}
