import 'package:zae_labeler/src/core/services/adaptive_data_loader.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';

import '../../../project/models/project_model.dart';
import '../../../../core/models/data_model.dart';
import '../../../../platform_helpers/storage/interface_storage_helper.dart';

/// 📦 LabelingDataManager
/// - 프로젝트 데이터를 로드하고, 현재 위치 관리, 이동 기능을 담당.
/// - LabelingViewModel 내부의 데이터 관련 책임을 분리.
///
/// 주요 책임:
/// - 초기 데이터 로드
/// - currentIndex 이동
/// - 현재 데이터 접근
class LabelingDataManager {
  final Project project;
  final StorageHelperInterface storageHelper;
  final List<UnifiedData>? initialDataList;
  final bool memoryOptimized;

  late List<UnifiedData> _dataList;
  int _currentIndex = 0;
  bool _isLoaded = false;

  LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList, this.memoryOptimized = false});

  /// ✅ 데이터 로드
  Future<void> load() async {
    _dataList = initialDataList ?? await loadDataAdaptively(project, storageHelper);
    _currentIndex = 0;
    _isLoaded = true;
  }

  bool get isLoaded => _isLoaded;
  List<UnifiedData> get allData => _dataList;
  UnifiedData get currentData => _dataList[_currentIndex];

  int get totalCount => _dataList.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _dataList.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  /// ✅ 인덱스 이동
  void moveNext() {
    if (hasNext) _currentIndex++;
  }

  void movePrevious() {
    if (hasPrevious) _currentIndex--;
  }

  void jumpTo(int index) {
    if (index >= 0 && index < _dataList.length) {
      _currentIndex = index;
    }
  }

  /// ✅ 상태 갱신
  LabelStatus get currentStatus => _dataList[_currentIndex].status;

  void updateStatusForCurrent(LabelStatus status) {
    _dataList[_currentIndex] = _dataList[_currentIndex].copyWith(status: status);
  }

  void updateStatus(String dataId, LabelStatus status) {
    final index = _dataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      _dataList[index] = _dataList[index].copyWith(status: status);
    }
  }

  /// ✅ 통계 정보
  int get completeCount => _dataList.where((e) => e.status == LabelStatus.complete).length;
  int get warningCount => _dataList.where((e) => e.status == LabelStatus.warning).length;
  int get incompleteCount => totalCount - completeCount;
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;

  void reset() {
    _currentIndex = 0;
    _isLoaded = false;
    _dataList = [];
  }
}
