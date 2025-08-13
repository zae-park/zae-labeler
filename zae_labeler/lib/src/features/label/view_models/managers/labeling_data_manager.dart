import 'package:zae_labeler/src/core/services/adaptive_data_loader.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';

import '../../../../core/models/project/project_model.dart';
import '../../../../core/models/data/data_model.dart';
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
  late List<UnifiedData> _dataList;
  final Map<String, LabelStatus> _statusMap = {};
  // final bool memoryOptimized;

  int _currentIndex = 0;
  int _completeCount = 0;
  int _warningCount = 0;
  bool _isLoaded = false;

  LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList});
  // LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList, this.memoryOptimized = false});

  /// ✅ 데이터 로드
  Future<void> load() async {
    _dataList = initialDataList ?? await loadDataAdaptively(project, storageHelper);
    _currentIndex = 0;
    _isLoaded = true;
  }

  /// ✅ 인덱스 이동
  void moveNext() => {if (hasNext) _currentIndex++};
  void movePrevious() => {if (hasPrevious) _currentIndex--};
  void jumpTo(int index) => {if (index >= 0 && index < _dataList.length) _currentIndex = index};

  void updateStatusForCurrent(LabelStatus status) => {_dataList[_currentIndex] = _dataList[_currentIndex].copyWith(status: status)};
  void updateStatus(String dataId, LabelStatus newStatus) {
    final oldStatus = _statusMap[dataId];
    if (oldStatus == LabelStatus.complete) _completeCount--;
    if (oldStatus == LabelStatus.warning) _warningCount--;
    if (newStatus == LabelStatus.complete) _completeCount++;
    if (newStatus == LabelStatus.warning) _warningCount++;
    _statusMap[dataId] = newStatus;
  }

  void reset() {
    _currentIndex = 0;
    _isLoaded = false;
    _dataList = [];
  }

  /// ✅ Getter & Setter

  bool get isLoaded => _isLoaded;
  List<UnifiedData> get allData => _dataList;
  UnifiedData get currentData => _dataList[_currentIndex];

  LabelStatus get currentStatus => _dataList[_currentIndex].status;
  int get totalCount => _dataList.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _dataList.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  /// ✅ 통계 정보
  int get completeCount => _completeCount;
  int get warningCount => _warningCount;
  int get incompleteCount => totalCount - _completeCount;
  double get progressRatio => totalCount == 0 ? 0.0 : _completeCount / totalCount;
}
