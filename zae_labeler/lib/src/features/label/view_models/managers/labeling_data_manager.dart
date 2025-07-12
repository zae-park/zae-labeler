import 'package:zae_labeler/src/core/services/adaptive_data_loader.dart';

import '../../../project/models/project_model.dart';
import '../../../../core/models/data_model.dart';
import '../../../../platform_helpers/storage/interface_storage_helper.dart';

/// 📦 DataManager
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

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  int _currentIndex = 0;
  late List<UnifiedData> _dataList;

  LabelingDataManager({
    required this.project,
    required this.storageHelper,
    this.initialDataList,
  });

  Future<void> load() async {
    _dataList = initialDataList ?? await loadDataAdaptively(project, storageHelper);
    _currentIndex = 0;
    _isLoaded = true;
  }

  UnifiedData get currentData => _dataList[_currentIndex];
  List<UnifiedData> get allData => _dataList;

  int get totalCount => _dataList.length;
  int get currentIndex => _currentIndex;

  void moveNext() {
    if (_currentIndex < _dataList.length - 1) _currentIndex++;
  }

  void movePrevious() {
    if (_currentIndex > 0) _currentIndex--;
  }

  void updateStatus(String dataId, LabelStatus status) {
    final index = _dataList.indexWhere((e) => e.dataId == dataId);
    if (index != -1) {
      _dataList[index] = _dataList[index].copyWith(status: status);
    }
  }

  int get completeCount => _dataList.where((e) => e.status == LabelStatus.complete).length;
  int get warningCount => _dataList.where((e) => e.status == LabelStatus.warning).length;
  int get incompleteCount => totalCount - completeCount;
  double get progressRatio => totalCount == 0 ? 0 : completeCount / totalCount;
}
