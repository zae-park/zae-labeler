import '../../models/data_model.dart';
import '../../models/project_model.dart';
import '../../utils/proxy_storage_helper/interface_storage_helper.dart';
import '../../utils/adaptive/adaptive_data_loader.dart';

/// 📦 라벨링에 필요한 데이터 리스트 및 현재 인덱스를 관리
class LabelDataManager {
  final Project project;
  final StorageHelperInterface storageHelper;
  final List<UnifiedData>? initialDataList;

  bool memoryOptimized = false;

  int _currentIndex = 0;
  List<UnifiedData> _unifiedDataList = [];
  UnifiedData _currentUnifiedData = UnifiedData.empty();

  LabelDataManager({
    required this.project,
    required this.storageHelper,
    this.initialDataList,
  });

  List<UnifiedData> get unifiedDataList => _unifiedDataList;
  UnifiedData get currentUnifiedData => _currentUnifiedData;
  int get currentIndex => _currentIndex;

  int get totalCount => _unifiedDataList.length;

  /// 초기화: 초기 데이터가 있으면 그것 사용, 없으면 storage 로딩
  Future<void> initialize() async {
    if (memoryOptimized) {
      _unifiedDataList = initialDataList ?? [];
    } else {
      _unifiedDataList = initialDataList ?? await loadDataAdaptively(project, storageHelper);
    }

    _currentUnifiedData = _unifiedDataList.isNotEmpty ? _unifiedDataList.first : UnifiedData.empty();
    _currentIndex = 0;
  }

  /// 현재 인덱스 기준 이동
  Future<bool> move(int delta) async {
    final newIndex = _currentIndex + delta;
    if (newIndex >= 0 && newIndex < _unifiedDataList.length) {
      _currentIndex = newIndex;
      _currentUnifiedData = _unifiedDataList[_currentIndex];
      return true;
    }
    return false;
  }

  Future<void> moveNext() => move(1);
  Future<void> movePrevious() => move(-1);

  /// 현재 데이터를 특정 인덱스 기준으로 설정
  void setCurrentIndex(int index) {
    if (index >= 0 && index < _unifiedDataList.length) {
      _currentIndex = index;
      _currentUnifiedData = _unifiedDataList[_currentIndex];
    }
  }

  void reset() {
    _unifiedDataList.clear();
    _currentUnifiedData = UnifiedData.empty();
    _currentIndex = 0;
  }
}
