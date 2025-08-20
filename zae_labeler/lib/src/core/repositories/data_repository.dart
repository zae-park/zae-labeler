import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';

import '../models/project/project_model.dart';
import '../../platform_helpers/storage/interface_storage_helper.dart';

/// ✅ DataRepository
/// - 프로젝트에 포함된 데이터(dataInfos, UnifiedData)를 로드/저장/관리하는 역할을 담당합니다.
/// - 프로젝트 내부의 데이터 흐름을 캡슐화하여 ViewModel 및 UseCase의 복잡도를 줄여줍니다.
class DataRepository {
  final StorageHelperInterface storageHelper;

  DataRepository({required this.storageHelper});

  // ===========================================================================
  // 📦 UnifiedData 관련
  // ===========================================================================

  /// ✅ UnifiedData 리스트를 로드합니다.
  ///
  /// - 플랫폼(web/native)에 따라 라벨 기반 혹은 파일 경로 기반으로 데이터를 구성합니다.
  /// - ViewModel 등 상위 계층은 플랫폼 구분 없이 동일하게 접근할 수 있습니다.
  Future<List<UnifiedData>> loadUnifiedData(Project project) async {
    return await loadDataAdaptively(project, storageHelper);
  }

  // ===========================================================================
  // 📁 DataInfo 관련 (project.dataInfos와 직접 관련)
  // ===========================================================================

  /// ✅ 프로젝트 객체 내부의 dataInfos 목록을 반환합니다.
  ///
  /// - 외부 저장소를 조회하지 않고, 메모리에 있는 프로젝트 인스턴스를 기준으로 반환됩니다.
  List<DataInfo> loadDataInfos(Project project) {
    return project.dataInfos;
  }

  /// ✅ 프로젝트 내의 dataInfos를 저장합니다.
  ///
  /// - StorageHelper의 saveProjectConfig는 프로젝트 단위로 저장되므로,
  ///   변경된 dataInfos가 반영된 프로젝트 전체를 저장합니다.
  Future<void> saveDataInfos(Project project) async {
    await storageHelper.saveProjectConfig([project]);
  }

  /// ✅ 프로젝트 설정 파일(JSON)을 외부로 내보냅니다.
  ///
  /// - 사용자가 프로젝트를 공유하거나 백업할 수 있도록 export합니다.
  /// - Web 환경에서는 다운로드 링크 제공 용도로 사용됩니다.
  Future<String> exportData(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  /// ✅ 외부에서 가져온 JSON 설정 파일에서 dataInfos를 복원합니다.
  ///
  /// - JSON은 복수의 프로젝트를 포함할 수 있지만, 일반적으로 첫 번째 프로젝트 기준으로 처리됩니다.
  /// - exportData()와 쌍을 이루는 동작입니다.
  Future<List<DataInfo>> importData(String configJson) async {
    final projects = await storageHelper.loadProjectFromConfig(configJson);
    if (projects.isEmpty) return [];
    return projects.first.dataInfos;
  }

  // ===========================================================================
  // ✏️ DataInfo 수정 (저장소 내에 있는 Project를 수정함)
  // ===========================================================================

  /// ✅ 특정 프로젝트의 dataInfos 전체를 새로운 리스트로 교체합니다.
  ///
  /// - 기존 리스트를 완전히 대체하며, 대량 등록 시 사용됩니다.
  Future<void> updateDataInfos(String projectId, List<DataInfo> newDataInfos) async {
    final projects = await storageHelper.loadProjectList();
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final updated = projects[index].copyWith(dataInfos: newDataInfos);
      projects[index] = updated;
      await storageHelper.saveProjectList(projects);
    }
  }

  /// ✅ 특정 프로젝트에 DataInfo 항목을 추가합니다.
  ///
  /// - 기존 리스트에 하나의 항목을 append합니다.
  /// - 사용자가 파일을 한 개 추가하거나 드래그 앤 드롭 시 호출됩니다.
  Future<void> addDataInfo(String projectId, DataInfo newDataInfo) async {
    final projects = await storageHelper.loadProjectList();
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final updated = projects[index].copyWith(dataInfos: [
        ...projects[index].dataInfos,
        newDataInfo,
      ]);
      projects[index] = updated;
      await storageHelper.saveProjectList(projects);
    }
  }

  /// ✅ 특정 DataInfo 항목을 삭제합니다.
  ///
  /// - `dataInfoId`를 기준으로 리스트에서 제거합니다.
  /// - UI에서 개별 삭제 시 사용됩니다.
  Future<void> removeDataInfoById(String projectId, String dataInfoId) async {
    final projects = await storageHelper.loadProjectList();
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final updated = projects[index].copyWith(
        dataInfos: projects[index].dataInfos.where((e) => e.id != dataInfoId).toList(),
      );
      projects[index] = updated;
      await storageHelper.saveProjectList(projects);
    }
  }
}
