import '../../features/project/models/project_model.dart';
import '../../core/models/data_model.dart';
import '../../platform_helpers/storage/interface_storage_helper.dart';

/// 📦 DataManager
/// - 프로젝트 데이터를 로드하고, 현재 위치 관리, 이동 기능을 담당.
/// - LabelingViewModel 내부의 데이터 관련 책임을 분리.
///
/// 주요 책임:
/// - 초기 데이터 로드
/// - currentIndex 이동
/// - 현재 데이터 접근
class DataManager {
  final Project project;
  final StorageHelperInterface storageHelper;

  late List<UnifiedData> _dataList;
  final int _currentIndex = 0;

  DataManager({required this.project, required this.storageHelper});

  /// 데이터를 로드하고 내부 상태를 초기화합니다.
  Future<void> load() async {
    // TODO: loadDataAdaptively() 등으로 로딩
  }

  /// 현재 위치의 데이터 반환
  UnifiedData get currentData => _dataList[_currentIndex];

  /// 전체 데이터 리스트 반환
  List<UnifiedData> get dataList => _dataList;

  /// 다음 데이터로 이동
  void moveNext() {
    // TODO: 인덱스 증가 + 예외처리
  }

  /// 이전 데이터로 이동
  void movePrevious() {
    // TODO: 인덱스 감소 + 예외처리
  }

  int get currentIndex => _currentIndex;
}
