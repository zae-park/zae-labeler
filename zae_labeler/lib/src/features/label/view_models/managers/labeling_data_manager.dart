import 'dart:collection';

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/features/data/models/data_with_status.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/features/label/models/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/get_storage_helper.dart';

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

  final List<DataWithStatus>? initialItems;
  final AdaptiveUnifiedDataLoader loader;

  List<DataWithStatus> _items = const [];

  int _currentIndex = 0;
  bool _isLoaded = false;

  int _completeCount = 0;
  int _warningCount = 0;

  LabelingDataManager({required this.project, required this.storageHelper, this.initialItems, AdaptiveUnifiedDataLoader? loader})
      : loader = loader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);

  /// ✅ 데이터 로드 (필요 시 placeholder 포함)
  Future<void> load() async {
    _items = initialItems ?? await loader.load(project);
    _currentIndex = 0;
    _recount();
    _isLoaded = true;
  }

  void _recount() {
    _completeCount = 0;
    _warningCount = 0;
    for (final it in _items) {
      if (it.status == LabelStatus.complete) _completeCount++;
      if (it.status == LabelStatus.warning) _warningCount++;
    }
  }

  /// ✅ 인덱스 이동
  void moveNext() => {if (hasNext) _currentIndex++};
  void movePrevious() => {if (hasPrevious) _currentIndex--};
  void jumpTo(int index) => {if (index >= 0 && index < _items.length) _currentIndex = index};

  // ========== 상태 갱신 ==========
  void updateStatusForCurrent(LabelStatus status) {
    final old = _items[_currentIndex].status;
    if (old == status) return;
    _items[_currentIndex] = DataWithStatus(data: _items[_currentIndex].data, status: status);
    _adjustCounts(old, status);
  }

  void updateStatusById(String dataId, LabelStatus status) {
    final i = _items.indexWhere((e) => e.data.dataId == dataId);
    if (i < 0) return;
    final old = _items[i].status;
    if (old == status) return;
    _items[i] = DataWithStatus(data: _items[i].data, status: status);
    _adjustCounts(old, status);
  }

  void _adjustCounts(LabelStatus old, LabelStatus next) {
    if (old == LabelStatus.complete) _completeCount--;
    if (old == LabelStatus.warning) _warningCount--;
    if (next == LabelStatus.complete) _completeCount++;
    if (next == LabelStatus.warning) _warningCount++;
  }

  /// 초기화
  void reset() {
    _currentIndex = 0;
    _isLoaded = false;
    _items = const [];
    _completeCount = 0;
    _warningCount = 0;
  }

  // ========== Getter ==========
  bool get isLoaded => _isLoaded;

  /// 화면에서 data만 필요할 때 편하게 쓰라고 제공
  List<UnifiedData> get allData => _items.map((e) => e.data).toList(growable: false);

  /// 필요하면 items 전체를 읽을 수도 있음(불변 뷰)
  UnmodifiableListView<DataWithStatus> get items => UnmodifiableListView(_items);

  UnifiedData get currentData => _items[_currentIndex].data;
  LabelStatus get currentStatus => _items[_currentIndex].status;

  int get totalCount => _items.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < totalCount - 1;
  bool get hasPrevious => _currentIndex > 0;

  // 통계
  int get completeCount => _completeCount;
  int get warningCount => _warningCount;
  int get incompleteCount => totalCount - _completeCount;
  double get progressRatio => totalCount == 0 ? 0.0 : _completeCount / totalCount;
}
