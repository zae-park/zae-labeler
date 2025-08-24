// lib/src/features/label/view_models/managers/labeling_data_manager.dart
import 'dart:collection';
import 'dart:typed_data';
import 'dart:convert' show base64Decode;

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';

import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';

import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';
import 'package:zae_labeler/src/utils/label_validator.dart';

/// 📦 LabelingDataManager
///
/// 단일 프로젝트에 대한 **데이터(파일) 목록과 라벨링 진행 상태**를 관리하는 경량 매니저입니다.
/// 이 매니저는 UI(ViewModel/Pages)와 저장소(Storage) 사이에서 아래 책임을 가집니다.
///
/// ### 책임
/// 1) **데이터 로드**: `AdaptiveUnifiedDataLoader`를 통해 `UnifiedData` 리스트를 파싱/획득
/// 2) **상태 로드/계산**: 저장소에서 라벨을 전량 로드 → `LabelValidator`로 각 데이터의 `LabelStatus` 계산
/// 3) **포커스/이동**: 현재 인덱스 관리(다음/이전/점프)
/// 4) **렌더 준비**: 뷰어가 즉시 사용할 수 있도록 렌더 소스를 준비(이미지: URL/Bytes 캐시, JSON/CSV: 파싱된 데이터)
/// 5) **프리로드**: 인접 항목(±1)에 대한 렌더 소스 선로드
///
/// ### 분리 원칙
/// - **데이터(`UnifiedData`)**와 **상태(`LabelStatus`)**를 분리하여 관리합니다.
///   - 데이터: `_dataList`
///   - 상태: `_statusMap` (key = dataId)
///
/// ### 로드 플로우
/// 1) `load()`: 로더로 `UnifiedData` 리스트 확보(상태 없음)
/// 2) 저장소에서 라벨 전량 로드 → `LabelValidator`로 상태 계산 → `_statusMap` 구성
///
/// ### 렌더 준비 우선순위 (이미지에 한정)
/// 1) `UnifiedData.imageBase64`
/// 2) `DataInfo.base64Content`
/// 3) `StorageHelperInterface.ensureLocalObjectUrl(info)`
/// 4) (웹/클라우드) `info.filePath`가 http(s)일 때만 `readDataBytes(info)`
///
/// JSON/CSV는 `UnifiedData` 단계에서 이미 파싱되어 있으므로 별도의 바이트 로딩이 필요하지 않습니다.
class LabelingDataManager {
  /// 현재 작업 중인 프로젝트 스냅샷
  final Project project;

  /// 플랫폼 의존 저장소 헬퍼(Blob URL/Bytes 로딩, 라벨 로드, URL 해제 등)
  final StorageHelperInterface storageHelper;

  /// 외부에서 이미 로드한 데이터가 있으면 그대로 사용(테스트/프리패치용)
  final List<UnifiedData>? initialDataList;

  /// 포맷/플랫폼에 적응하는 데이터 로더
  final AdaptiveUnifiedDataLoader loader;

  /// 전체 데이터 리스트(unmodifiable getter 제공)
  List<UnifiedData> _dataList = const [];

  /// 데이터ID → 라벨 상태 맵
  final Map<String, LabelStatus> _statusMap = {};

  /// 데이터ID → Blob/HTTP URL 캐시(이미지 전용)
  final Map<String, String> _urlCache = {};

  /// 데이터ID → Bytes 캐시(이미지 전용)
  final Map<String, Uint8List> _bytesCache = {};

  /// 현재 포커스 인덱스
  int _currentIndex = 0;

  /// 로드 완료 여부
  bool _isLoaded = false;

  /// 통계 (완료/경고)
  int _completeCount = 0;
  int _warningCount = 0;

  /// 생성자
  ///
  /// - [project]: 대상 프로젝트
  /// - [storageHelper]: 플랫폼별 스토리지 어댑터
  /// - [initialDataList]: 외부에서 미리 로드한 데이터가 있다면 사용(옵션)
  /// - [loader]: 주입 없으면 기본 `AdaptiveUnifiedDataLoader` 생성
  LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList, AdaptiveUnifiedDataLoader? loader})
      : loader = loader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);

  // ───────────────────────────────────────────
  // 🚚 Load / State
  // ───────────────────────────────────────────

  /// 프로젝트의 데이터와 상태를 함께 로드합니다.
  ///
  /// 동작:
  /// 1) 데이터 로더로 `UnifiedData` 리스트 로드(상태 없음)
  /// 2) 저장소에서 모든 라벨 로드 → `LabelValidator`로 상태 계산 → `_statusMap` 구성
  Future<void> load() async {
    _dataList = initialDataList ?? await loader.load(project);
    _currentIndex = 0;

    await _rebuildStatusMapFromStorage();
    _isLoaded = true;
  }

  /// 저장소에서 라벨 전량 로드 후, 데이터ID 기준으로 상태맵을 재구성합니다.
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

  // ───────────────────────────────────────────
  // 🖼️ Render readiness
  // ───────────────────────────────────────────

  /// 현재 포커스된 항목을 **뷰어가 바로 사용할 수 있도록** 준비합니다.
  ///
  /// - 이미지: URL(Blob/HTTP) 또는 Bytes 캐시 준비
  /// - JSON/CSV: `UnifiedData`에 이미 파싱되어 있어 추가 준비 불필요
  ///
  /// 우선순위(이미지 한정):
  /// 1) `UnifiedData.imageBase64`
  /// 2) `DataInfo.base64Content`
  /// 3) `ensureLocalObjectUrl(info)` (Blob/HTTP)
  /// 4) http(s) 경로일 때만 `readDataBytes(info)`
  Future<void> ensureRenderableReadyForCurrent() async {
    final ud = currentData;
    final info = ud.dataInfo;

    // 이미지 외 타입은 별도 준비 불필요(JSON/CSV는 UnifiedData에 이미 있음)
    if (ud.fileType != FileType.image) return;

    // 0) UnifiedData의 base64 우선
    if ((ud.imageBase64 ?? '').isNotEmpty) {
      _bytesCache[info.id] = base64Decode(ud.imageBase64!);
      return;
    }

    // 1) DataInfo의 base64Content
    if ((info.base64Content ?? '').isNotEmpty) {
      _bytesCache[info.id] = base64Decode(info.base64Content!);
      return;
    }

    // 2) URL(Blob/HTTP) 확보
    final url = await storageHelper.ensureLocalObjectUrl(info);
    if (url != null && url.isNotEmpty) {
      _urlCache[info.id] = url;
      return;
    }

    // 3) 마지막 수단: http(s) 경로만 bytes 로드
    final p = info.filePath ?? '';
    final looksHttp = p.startsWith('http://') || p.startsWith('https://');
    if (!looksHttp) {
      debugPrint('[LabelingDataManager] skip readDataBytes: no http(s) path for ${info.fileName}');
      return;
    }

    final bytes = await storageHelper.readDataBytes(info);
    _bytesCache[info.id] = bytes;
  }

  /// 주변 항목(±1)에 대해 프리로드를 수행합니다. (이미지 한정)
  ///
  /// 이미지가 아닌 타입(Object/Series)은 `UnifiedData`에 이미 파싱되어 있으므로 프리로드 불필요.
  Future<void> preloadAround() async {
    for (final i in [currentIndex - 1, currentIndex + 1]) {
      if (i < 0 || i >= allData.length) continue;

      final ud = allData[i];
      if (ud.fileType != FileType.image) continue; // 이미지 외 스킵
      final info = ud.dataInfo;

      // base64가 있다면 즉시 Bytes 캐시
      if (!_bytesCache.containsKey(info.id)) {
        if ((ud.imageBase64 ?? '').isNotEmpty) {
          _bytesCache[info.id] = base64Decode(ud.imageBase64!);
          continue;
        }
        if ((info.base64Content ?? '').isNotEmpty) {
          _bytesCache[info.id] = base64Decode(info.base64Content!);
          continue;
        }
      }

      // URL or bytes
      if (!_urlCache.containsKey(info.id) && !_bytesCache.containsKey(info.id)) {
        final url = await storageHelper.ensureLocalObjectUrl(info);
        if (url != null && url.isNotEmpty) {
          _urlCache[info.id] = url;
        } else {
          final p = info.filePath ?? '';
          final looksHttp = p.startsWith('http://') || p.startsWith('https://');
          if (!looksHttp) {
            debugPrint('[LabelingDataManager] preload skip readDataBytes: no http(s) for ${info.fileName}');
            continue;
          }
          final bytes = await storageHelper.readDataBytes(info);
          _bytesCache[info.id] = bytes;
        }
      }
    }
  }

  /// 현재 항목이 **렌더 준비 완료**인지 판별합니다.
  ///
  /// - 이미지: URL 또는 Bytes 캐시가 있으면 true
  /// - JSON: `objectData`가 null이 아니면 true
  /// - CSV: `seriesData`가 null/empty가 아니면 true
  bool isCurrentReady() {
    final ud = currentData;
    final info = ud.dataInfo;

    switch (ud.fileType) {
      case FileType.image:
        final urlReady = (_urlCache[info.id]?.isNotEmpty ?? false);
        final bytesReady = _bytesCache.containsKey(info.id);
        return urlReady || bytesReady;

      case FileType.object:
        return ud.objectData != null;

      case FileType.series:
        final s = ud.seriesData;
        return s != null && s.isNotEmpty;

      default:
        return false;
    }
  }

  /// 뷰어에서 사용할 **렌더 소스**를 반환합니다.
  ///
  /// - 이미지: `String`(Blob/HTTP URL) 또는 `Uint8List`(Bytes)
  /// - JSON:   `Object?`(대개 `Map<String,dynamic>` 또는 `List`)
  /// - CSV:    `List<double>`
  ///
  /// 준비되지 않은 경우 `null`을 반환합니다.
  Object? currentRenderable() {
    final ud = currentData;
    final info = ud.dataInfo;

    switch (ud.fileType) {
      case FileType.image:
        final url = _urlCache[info.id];
        if (url != null && url.isNotEmpty) return url;
        final bytes = _bytesCache[info.id];
        return bytes; // 없으면 null

      case FileType.object:
        return ud.objectData;

      case FileType.series:
        return ud.seriesData;

      default:
        return null;
    }
  }

  // ───────────────────────────────────────────
  // 🔁 Status update
  // ───────────────────────────────────────────

  /// 현재 포커스된 항목의 상태를 갱신합니다.
  void updateStatusForCurrent(LabelStatus status) {
    final id = currentData.dataId;
    _updateStatusInternal(id, status);
  }

  /// 특정 데이터ID의 상태를 갱신합니다.
  void updateStatusById(String dataId, LabelStatus status) {
    _updateStatusInternal(dataId, status);
  }

  void _updateStatusInternal(String dataId, LabelStatus next) {
    final old = _statusMap[dataId] ?? LabelStatus.incomplete;
    if (old == next) return;

    // 카운터 보정
    if (old == LabelStatus.complete) _completeCount--;
    if (old == LabelStatus.warning) _warningCount--;
    if (next == LabelStatus.complete) _completeCount++;
    if (next == LabelStatus.warning) _warningCount++;

    _statusMap[dataId] = next;
  }

  /// 저장소 기준으로 상태맵을 전량 갱신합니다. (라벨 변경이 외부에서 일어난 경우 등)
  Future<void> refreshAllStatusesFromStorage() async {
    await _rebuildStatusMapFromStorage();
  }

  /// 모든 항목의 상태를 `incomplete`로 리셋합니다. (라벨 초기화 직후 사용)
  void resetAllStatusesToIncomplete() {
    for (final id in _statusMap.keys) {
      _statusMap[id] = LabelStatus.incomplete;
    }
    _recount();
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
  // 🔀 Navigation
  // ───────────────────────────────────────────

  /// 다음 항목으로 이동합니다.
  void moveNext() {
    if (hasNext) _currentIndex++;
  }

  /// 이전 항목으로 이동합니다.
  void movePrevious() {
    if (hasPrevious) _currentIndex--;
  }

  /// 특정 인덱스로 점프합니다.
  void jumpTo(int index) {
    if (index >= 0 && index < _dataList.length) _currentIndex = index;
  }

  // ───────────────────────────────────────────
  // ♻️ Lifecycle
  // ───────────────────────────────────────────

  /// 내부 상태를 초기화합니다. (데이터/상태/통계/포커스)
  void reset() {
    _currentIndex = 0;
    _isLoaded = false;
    _dataList = const [];
    _statusMap.clear();
    _completeCount = 0;
    _warningCount = 0;
    _urlCache.clear();
    _bytesCache.clear();
  }

  /// 보유 중인 Blob URL을 해제하고 캐시를 모두 비웁니다.
  void dispose() {
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

  /// 데이터/상태 로드 완료 여부
  bool get isLoaded => _isLoaded;

  /// 데이터 리스트(읽기 전용 뷰)
  List<UnifiedData> get allData => _dataList;

  /// 상태 맵(읽기 전용 뷰)
  UnmodifiableMapView<String, LabelStatus> get statusMap => UnmodifiableMapView(_statusMap);

  /// 현재 포커스된 데이터
  UnifiedData get currentData => _dataList[_currentIndex];

  /// 현재 포커스된 데이터의 상태 (없으면 `incomplete`)
  LabelStatus get currentStatus => _statusMap[currentData.dataId] ?? LabelStatus.incomplete;

  /// 특정 데이터ID의 상태 (없으면 `incomplete`)
  LabelStatus statusOf(String dataId) => _statusMap[dataId] ?? LabelStatus.incomplete;

  /// 총 데이터 개수
  int get totalCount => _dataList.length;

  /// 현재 인덱스
  int get currentIndex => _currentIndex;

  /// 다음 항목 존재 여부
  bool get hasNext => _currentIndex < totalCount - 1;

  /// 이전 항목 존재 여부
  bool get hasPrevious => _currentIndex > 0;

  /// 완료/경고/미완료 개수 및 진행률
  int get completeCount => _completeCount;
  int get warningCount => _warningCount;
  int get incompleteCount => totalCount - _completeCount;
  double get progressRatio => totalCount == 0 ? 0.0 : _completeCount / totalCount;
}
