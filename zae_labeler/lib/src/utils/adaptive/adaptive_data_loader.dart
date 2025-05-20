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
///   - 라벨이 전혀 없는 신규 프로젝트의 경우, `project.dataPaths`를 fallback으로 사용해 초기 구성을 시도합니다.
///   - 그래도 없을 경우 placeholder `UnifiedData`를 최소 1개 반환하여 ViewModel이 안전하게 진입할 수 있도록 합니다.
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

  // ✅ fallback: dataPaths가 있는 경우 초기화에 사용
  if (fallbackPaths.isNotEmpty) {
    return await Future.wait(fallbackPaths.map(UnifiedData.fromDataPath));
  }

  // ⚠️ 라벨도, 데이터도 없으면 placeholder 반환
  debugPrint("⚠️ [AdaptiveLoader] No labels and no fallbackPaths → returning placeholder");
  return [UnifiedData(dataId: 'placeholder', fileName: 'untitled', fileType: FileType.unsupported, content: null, status: LabelStatus.incomplete)];
}
