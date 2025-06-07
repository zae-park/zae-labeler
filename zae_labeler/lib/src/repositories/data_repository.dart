// lib/src/repositories/data_repository.dart

import 'package:zae_labeler/src/models/project_model.dart';
import 'package:zae_labeler/src/models/data_model.dart';
import 'package:zae_labeler/src/utils/storage_helper.dart';

/// ✅ DataRepository
/// - 프로젝트 내 데이터 파일 정보의 저장/불러오기/삭제/내보내기 담당
/// - DataInfo 및 UnifiedData 관련 로직을 캡슐화
class DataRepository {
  final StorageHelperInterface storageHelper;

  DataRepository({required this.storageHelper});

  /// 📌 전체 DataInfo 목록 저장
  /// - 주로 프로젝트 설정 저장 시 호출됨
  Future<void> saveDataInfos(Project project) async {
    await storageHelper.saveProjectConfig([project]);
  }

  /// 📌 프로젝트에서 등록된 DataInfo 목록 로드
  /// - Firestore에서는 프로젝트에 내장된 dataInfos 사용
  List<DataInfo> loadDataInfos(Project project) {
    return project.dataInfos;
  }

  /// 📌 전체 데이터 파일 내보내기 (ZIP 또는 JSON)
  /// - Firebase Web의 경우는 downloadProjectConfig() 사용
  Future<String> exportData(Project project) async {
    return await storageHelper.downloadProjectConfig(project);
  }

  /// 📌 외부에서 데이터 파일 복원
  /// - 현재 Web에서는 미사용
  Future<List<DataInfo>> importData(String configJson) async {
    final projects = await storageHelper.loadProjectFromConfig(configJson);
    if (projects.isEmpty) {
      return [];
    }
    return projects.first.dataInfos;
  }
}
