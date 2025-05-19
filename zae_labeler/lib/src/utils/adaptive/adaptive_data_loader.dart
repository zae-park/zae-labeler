// 📁 lib/utils/adaptive/adaptive_data_loader.dart

import 'package:flutter/foundation.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../proxy_storage_helper/interface_storage_helper.dart';

/// {@template adaptive_data_loader}
/// 플랫폼에 따라 프로젝트의 데이터를 적절하게 불러오기 위한 어댑터 함수입니다.
///
/// ✅ 목적:
/// - `UnifiedData`는 라벨링 화면에서 필요한 핵심 데이터 구조입니다.
/// - 그러나 플랫폼에 따라 `UnifiedData`를 구성하는 방식이 달라야 합니다.
///
/// ✅ 책임:
/// - **Native 환경 (mobile/desktop)**:
///   - 프로젝트 내 `dataPaths` 목록을 기반으로 `UnifiedData.fromDataPath()`를 호출합니다.
///   - 파일 시스템 접근이 가능하므로, 실제 파일 경로에서 데이터를 로드합니다.
///
/// - **Web 환경**:
///   - 로컬 파일 경로 접근이 불가능하므로 `dataPaths`를 사용할 수 없습니다.
///   - 대신, 이미 저장된 `LabelModel` 목록을 기반으로 `UnifiedData`를 재구성합니다.
///   - 이 때 `dataId`와 `fileName`을 기반으로 최소한의 정보를 복원합니다.
///   - 라벨이 전혀 없는 신규 프로젝트의 경우, `project.dataPaths`를 fallback으로 사용해 초기 구성을 시도합니다.
///
/// 이 어댑터는 MVVM 구조 내에서 ViewModel이 플랫폼 차이를 인식하지 않고 일관된 방식으로 데이터를 처리할 수 있도록 돕습니다.
/// {@endtemplate}
Future<List<UnifiedData>> loadDataAdaptively(Project project, StorageHelperInterface storageHelper) async {
  if (kIsWeb) {
    return await _loadFromLabels(project.id, storageHelper, project.dataPaths);
  } else {
    return await Future.wait(project.dataPaths.map(UnifiedData.fromDataPath));
  }
}

/// Web에서는 저장된 라벨을 기반으로 `UnifiedData`를 구성하거나, fallback으로 `dataPaths`를 사용할 수 있습니다.
Future<List<UnifiedData>> _loadFromLabels(
  String projectId,
  StorageHelperInterface storageHelper,
  List<DataPath> fallbackPaths,
) async {
  final List<LabelModel> labels = await storageHelper.loadAllLabelModels(projectId);

  if (labels.isNotEmpty) {
    return labels.map((label) {
      return UnifiedData(
        dataId: label.dataId,
        fileName: label.dataPath?.split('/').last ?? label.dataId,
        fileType: FileType.image,
        content: null,
        status: label.isLabeled ? LabelStatus.complete : LabelStatus.incomplete,
      );
    }).toList();
  }

  // ✅ 라벨도 없고 fallbackPaths도 비어 있으면, 사용자에게 안내 필요
  if (fallbackPaths.isEmpty) {
    debugPrint("⚠️ [AdaptiveLoader] No labels or dataPaths available for project: $projectId");
    return [];
  }

  // ✅ Web 초기 진입 시: 프로젝트 생성 직후 fallback으로 데이터 구성
  return await Future.wait(fallbackPaths.map(UnifiedData.fromDataPath));
}
