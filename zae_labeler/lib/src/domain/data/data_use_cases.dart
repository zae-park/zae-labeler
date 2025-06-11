import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../repositories/data_repository.dart';

/// ✅ DataUseCases
/// - UnifiedData, DataInfo 관련 UseCase 집합
/// - LabelingDataManager 및 설정/내보내기 기능 등에서 호출
class DataUseCases {
  final DataRepository dataRepository;

  DataUseCases({required this.dataRepository});

  /// 📌 UnifiedData 전체 로딩
  /// - 플랫폼(Web/Native)에 따라 경로 또는 라벨 기반 로딩 방식 분기
  Future<List<UnifiedData>> loadUnifiedData(Project project) {
    return dataRepository.loadUnifiedData(project);
  }

  /// 📌 프로젝트 설정 저장 시 DataInfo도 함께 저장
  Future<void> saveDataInfos(Project project) {
    return dataRepository.saveDataInfos(project);
  }

  /// 📌 설정 페이지 등에서 현재 프로젝트에 등록된 DataInfo 조회
  List<DataInfo> loadDataInfos(Project project) {
    return dataRepository.loadDataInfos(project);
  }

  /// 📌 데이터 설정 전체 내보내기 (config json or zip)
  Future<String> exportData(Project project) {
    return dataRepository.exportData(project);
  }

  /// 📌 외부에서 프로젝트 설정 JSON을 불러와 DataInfo 복원
  Future<List<DataInfo>> importData(String configJson) {
    return dataRepository.importData(configJson);
  }
}
