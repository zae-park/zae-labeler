// lib/src/features/label/view_models/managers/labeling_data_manager.dart
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';

import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';

import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';

/// 📦 LabelingDataManager
/// - 프로젝트의 데이터(파일)를 로드하고, 현재 포커스/이동/상태(진행률)만 관리.
/// - **데이터(UnifiedData)**와 **상태(LabelStatus)**를 분리해 관리한다.
///   - 데이터: `_dataList`
///   - 상태:  `_statusMap` (key = dataId)
///
/// 로드 흐름:
///   1) `AdaptiveUnifiedDataLoader`로 `UnifiedData` 리스트를 가져옴(상태 없음)
///   2) 저장소에서 해당 프로젝트의 라벨 전부 로드 → `LabelValidator`로 상태 계산 → `_statusMap` 구성
///
/// 뷰모델/화면 쪽에서 라벨이 저장될 때는 `updateStatusForCurrent` 또는
/// `updateStatusById`로 상태만 갱신해주면 통계/프로그레스가 즉시 반영된다.
class LabelingDataManager {
  final Project project;
  final StorageHelperInterface storageHelper;

  /// 외부에서 이미 로드한 데이터가 있으면 그대로 사용 (테스트/프리패치용)
  final List<UnifiedData>? initialDataList;

  /// 데이터 로더 (플랫폼/포맷 적응)
  final AdaptiveUnifiedDataLoader loader;

  List<UnifiedData> _dataList = const [];
  final Map<String, LabelStatus> _statusMap = {};
  final Map<String, String> _urlCache = {};
  final Map<String, Uint8List> _bytesCache = {};

  int _currentIndex = 0;
  bool _isLoaded = false;

  int _completeCount = 0;
  int _warningCount = 0;

  LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList, AdaptiveUnifiedDataLoader? loader})
      : loader = loader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);

  /// ✅ 데이터 + 상태 로드
  /// - 데이터: loader로 파싱
  /// - 상태: 저장소 라벨 → LabelValidator로 계산
  Future<void> load() async {
    // 1) 데이터 로드 (status 없음)
    _dataList = initialDataList ?? await loader.load(project);
    _currentIndex = 0;

    // 2) 라벨 로드 → 상태 계산
    await _rebuildStatusMapFromStorage();

    _isLoaded = true;
  }

  /// 저장소에서 라벨 전부 로드 → 상태맵 재구성
  Future<void> _rebuildStatusMapFromStorage() async {
    _statusMap.clear();
    List<LabelModel> labels = const [];
    try {
      labels = await storageHelper.loadAllLabelModels(project.id);
    } catch (e) {
      debugPrint("❌ [LabelingDataManager] Failed to load labels: $e");
    }
    final byId = {for (final m in labels) m.dataId: m};

    for (final info in project.dataInfos) {
      final lbl = byId[info.id];
      _statusMap[info.id] = LabelValidator.getStatus(project, lbl);
    }
    _recount();
  }

  // ✅ 현재 아이템을 뷰어가 바로 쓸 수 있게 준비
  Future<void> ensureRenderableReadyForCurrent() async {
    final info = currentData.dataInfo;
    // 1) URL 선호(웹 성능 ↑)
    final url = await storageHelper.ensureLocalObjectUrl(info);
    if (url != null) {
      _urlCache[info.id] = url;
      return;
    }
    // 2) URL 생성 불가 → bytes 로드
    final bytes = await storageHelper.readDataBytes(info);
    _bytesCache[info.id] = bytes;
  }

  // ✅ 주변 프리로드(±1)
  Future<void> preloadAround() async {
    for (final i in [currentIndex - 1, currentIndex + 1]) {
      if (i < 0 || i >= allData.length) continue;
      final info = allData[i].dataInfo;
      if (!_urlCache.containsKey(info.id) && !_bytesCache.containsKey(info.id)) {
        final url = await storageHelper.ensureLocalObjectUrl(info);
        if (url != null) {
          _urlCache[info.id] = url;
        } else {
          final bytes = await storageHelper.readDataBytes(info);
          _bytesCache[info.id] = bytes;
        }
      }
    }
  }

  /// 위젯에서 사용할 렌더 소스(String: URL/Blob URL 또는 Uint8List)
  Object? currentRenderable() {
    final info = currentData.dataInfo;
    final url = _urlCache[info.id];
    if (url != null && url.isNotEmpty) return url;
    final bytes = _bytesCache[info.id];
    return bytes; // 없으면 null
  }

  void _recount() {
    _completeCount = 0;
    _warningCount = 0;
    for (final s in _statusMap.values) {
      if (s == LabelStatus.complete) _completeCount++;
      if (s == LabelStatus.warning) _warningCount++;
    }
  }

  // ───────────────────────────────────────────
  // 🔀 인덱스 이동
  // ───────────────────────────────────────────
  void moveNext() {
    if (hasNext) _currentIndex++;
  }

  void movePrevious() {
    if (hasPrevious) _currentIndex--;
  }

  void jumpTo(int index) {
    if (index >= 0 && index < _dataList.length) _currentIndex = index;
  }

  // ───────────────────────────────────────────
  // 🔁 상태 갱신(라벨 저장 이후 호출)
  // ───────────────────────────────────────────
  void updateStatusForCurrent(LabelStatus status) {
    final id = currentData.dataId;
    _updateStatusInternal(id, status);
  }

  void updateStatusById(String dataId, LabelStatus status) {
    _updateStatusInternal(dataId, status);
  }

  void _updateStatusInternal(String dataId, LabelStatus next) {
    final old = _statusMap[dataId] ?? LabelStatus.incomplete;
    if (old == next) return;

    // 카운트 조정
    if (old == LabelStatus.complete) _completeCount--;
    if (old == LabelStatus.warning) _warningCount--;
    if (next == LabelStatus.complete) _completeCount++;
    if (next == LabelStatus.warning) _warningCount++;

    _statusMap[dataId] = next;
  }

  /// 필요 시: 저장소 상태(라벨) 기준으로 다시 전량 재계산
  Future<void> refreshAllStatusesFromStorage() async {
    await _rebuildStatusMapFromStorage();
  }

  /// 필요 시: 현 상태맵을 전부 미완료로 리셋(라벨 초기화 직후 등)
  void resetAllStatusesToIncomplete() {
    for (final id in _statusMap.keys) {
      _statusMap[id] = LabelStatus.incomplete;
    }
    _recount();
  }

  // ───────────────────────────────────────────
  // ♻️ 초기화
  // ───────────────────────────────────────────
  void reset() {
    _currentIndex = 0;
    _isLoaded = false;
    _dataList = const [];
    _statusMap.clear();
    _completeCount = 0;
    _warningCount = 0;
  }

  void dispose() {
    // 웹 Blob URL 해제
    for (final u in _urlCache.values) {
      // ignore: discarded_futures
      storageHelper.revokeLocalObjectUrl(u);
    }
    _urlCache.clear();
    _bytesCache.clear();
  }

  // ───────────────────────────────────────────
  // 🔎 Getters
  // ───────────────────────────────────────────
  bool get isLoaded => _isLoaded;

  /// 화면에서 데이터만 필요할 때 사용
  List<UnifiedData> get allData => _dataList;

  /// 상태 맵 읽기 전용 뷰
  UnmodifiableMapView<String, LabelStatus> get statusMap => UnmodifiableMapView(_statusMap);

  UnifiedData get currentData => _dataList[_currentIndex];

  LabelStatus get currentStatus => _statusMap[currentData.dataId] ?? LabelStatus.incomplete;

  LabelStatus statusOf(String dataId) => _statusMap[dataId] ?? LabelStatus.incomplete;

  int get totalCount => _dataList.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < totalCount - 1;
  bool get hasPrevious => _currentIndex > 0;

  // 통계
  int get completeCount => _completeCount;
  int get warningCount => _warningCount;
  int get incompleteCount => totalCount - _completeCount;
  double get progressRatio => totalCount == 0 ? 0.0 : _completeCount / totalCount;
}
