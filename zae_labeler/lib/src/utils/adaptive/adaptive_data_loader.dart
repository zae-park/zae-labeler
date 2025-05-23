// lib/utils/adaptive/adaptive_data_loader.dart
import 'package:flutter/foundation.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../proxy_storage_helper/interface_storage_helper.dart';

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
  } catch (e, _) {
    debugPrint("❌ [AdaptiveLoader] loadAllLabelModels 실패: $e");
  }

  // ✅ 모든 데이터 먼저 변환
  final allData = await Future.wait(project.dataInfos.map(UnifiedData.fromDataInfo));

  // ✅ 라벨이 존재하면 해당 dataId의 상태만 업데이트
  for (final label in labels) {
    final i = allData.indexWhere((d) => d.dataId == label.dataId);
    if (i != -1) {
      allData[i] = allData[i].copyWith(
        status: label.isLabeled ? LabelStatus.complete : LabelStatus.incomplete,
      );
    }
  }

  // ✅ 라벨도 없고 데이터도 없을 때는 placeholder
  if (allData.isEmpty) {
    debugPrint("⚠️ [AdaptiveLoader] No labels and no dataInfos → returning placeholder");
    return [UnifiedData(dataId: 'placeholder', fileName: 'untitled', fileType: FileType.unsupported)];
  }

  return allData;
}

/// Native: project.dataInfos에서 dataId → filePath를 resolve하여 구성
Future<List<UnifiedData>> _loadFromPaths(Project project) async {
  if (project.dataInfos.isEmpty) {
    debugPrint("⚠️ [AdaptiveLoader] No dataInfos found → returning placeholder");
    return [UnifiedData(dataId: 'placeholder', fileName: 'untitled', fileType: FileType.unsupported, content: null, status: LabelStatus.incomplete)];
  }

  return Future.wait(project.dataInfos.map((e) => UnifiedData.fromDataInfo(e)));
}
