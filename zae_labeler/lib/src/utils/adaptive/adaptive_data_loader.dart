// 📁 lib/utils/adaptive/adaptive_data_loader.dart
import 'package:flutter/foundation.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../proxy_storage_helper/interface_storage_helper.dart';

/// 프로젝트와 스토리지 헬퍼를 기반으로 플랫폼에 맞게 UnifiedData를 반환합니다.
Future<List<UnifiedData>> loadDataAdaptively(Project project, StorageHelperInterface storageHelper) async {
  if (kIsWeb) {
    return await _loadFromLabels(project.id, storageHelper);
  } else {
    return await Future.wait(project.dataPaths.map(UnifiedData.fromDataPath));
  }
}

/// Web에서는 저장된 라벨 목록을 기준으로 UnifiedData를 재구성합니다.
Future<List<UnifiedData>> _loadFromLabels(String projectId, StorageHelperInterface storageHelper) async {
  final List<LabelModel> labels = await storageHelper.loadAllLabelModels(projectId);

  return labels.map((label) {
    return UnifiedData(
      dataId: label.dataId,
      fileName: label.dataPath?.split('/').last ?? label.dataId,
      fileType: FileType.image,
      content: null,
      status: LabelStatus.incomplete,
    );
  }).toList();
}
