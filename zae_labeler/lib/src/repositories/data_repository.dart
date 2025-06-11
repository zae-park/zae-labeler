import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../utils/adaptive/adaptive_data_loader.dart';

class DataRepository {
  final StorageHelperInterface storageHelper;

  DataRepository({required this.storageHelper});

  /// 📌 프로젝트로부터 UnifiedData 리스트를 Adaptive하게 불러옴
  Future<List<UnifiedData>> loadUnifiedData(Project project) async {
    return await loadDataAdaptively(project, storageHelper);
  }

  /// 📌 dataInfo 저장 (프로젝트 전체 저장)
  Future<void> saveDataInfos(Project project) async {
    await storageHelper.saveProjectConfig([project]);
  }

  /// 📌 project에 등록된 dataInfos 반환
  List<DataInfo> loadDataInfos(Project project) {
    return project.dataInfos;
  }

  /// 📌 프로젝트 설정 JSON 내보내기
  Future<String> exportData(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  /// 📌 외부 JSON으로부터 dataInfo 복원
  Future<List<DataInfo>> importData(String configJson) async {
    final projects = await storageHelper.loadProjectFromConfig(configJson);
    if (projects.isEmpty) return [];
    return projects.first.dataInfos;
  }
}
