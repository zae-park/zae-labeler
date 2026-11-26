// lib/src/features/label/view_models/labeling_data_manager.dart
import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/data/file_type.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/data/services/adaptive_unified_data_loader.dart';
import 'package:zae_labeler/src/features/data/services/unified_data_service.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

/// 📦 LabelingDataManager
///
/// 단일 프로젝트의 **데이터(파일) 목록, 포커스 인덱스, 렌더 소스 캐시**를 관리합니다.
/// 라벨과 라벨 상태는 다루지 않습니다(→ `LabelingViewModel`이 단일 소스로 관리).
///
/// ### 렌더 준비 우선순위 (이미지 한정)
/// 1) `UnifiedData.imageBase64`
/// 2) `DataInfo.base64Content`
/// 3) `StorageHelperInterface.ensureLocalObjectUrl(info)` (Blob/HTTP URL)
/// 4) `info.filePath`가 http(s)일 때만 `readDataBytes(info)`
///
/// JSON/CSV는 `UnifiedData` 단계에서 이미 파싱되어 있으므로 별도 준비가 필요 없습니다.
class LabelingDataManager {
  final Project project;
  final StorageHelperInterface storageHelper;

  /// 외부에서 이미 로드한 데이터가 있으면 그대로 사용(테스트/프리패치용)
  final List<UnifiedData>? initialDataList;

  final AdaptiveUnifiedDataLoader loader;

  List<UnifiedData> _dataList = const [];
  final Map<String, String> _urlCache = {};
  final Map<String, Uint8List> _bytesCache = {};
  int _currentIndex = 0;
  bool _isLoaded = false;

  LabelingDataManager({required this.project, required this.storageHelper, this.initialDataList, AdaptiveUnifiedDataLoader? loader})
    : loader = loader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);

  // ───────────────────────────────────────────
  // 🚚 Load
  // ───────────────────────────────────────────

  Future<void> load() async {
    _dataList = List.unmodifiable(initialDataList ?? await loader.load(project));
    _currentIndex = 0;
    _isLoaded = true;
  }

  // ───────────────────────────────────────────
  // 🖼️ Render readiness
  // ───────────────────────────────────────────

  /// 현재 항목을 뷰어가 바로 사용할 수 있도록 준비합니다. 데이터가 없으면 아무것도 하지 않습니다.
  Future<void> ensureRenderableReadyForCurrent() async {
    if (isEmpty) return;
    await _prepare(currentData);
  }

  /// 주변 항목(±1)의 렌더 소스를 미리 준비합니다. (이미지 한정)
  Future<void> preloadAround() async {
    for (final i in [_currentIndex - 1, _currentIndex + 1]) {
      if (i < 0 || i >= _dataList.length) continue;
      try {
        await _prepare(_dataList[i]);
      } catch (e) {
        debugPrint('[LabelingDataManager] preload failed for ${_dataList[i].fileName}: $e');
      }
    }
  }

  Future<void> _prepare(UnifiedData ud) async {
    if (ud.fileType != FileType.image) return;
    final info = ud.dataInfo;
    if (_urlCache.containsKey(info.id) || _bytesCache.containsKey(info.id)) return;

    final inline = _inlineBytes(ud, info);
    if (inline != null) {
      _bytesCache[info.id] = inline;
      return;
    }

    final url = await storageHelper.ensureLocalObjectUrl(info);
    if (url != null && url.isNotEmpty) {
      _urlCache[info.id] = url;
      return;
    }

    final path = info.filePath ?? '';
    if (!(path.startsWith('http://') || path.startsWith('https://'))) {
      debugPrint('[LabelingDataManager] skip readDataBytes: no http(s) path for ${info.fileName}');
      return;
    }
    _bytesCache[info.id] = await storageHelper.readDataBytes(info);
  }

  Uint8List? _inlineBytes(UnifiedData ud, DataInfo info) {
    final b64 = (ud.imageBase64 ?? '').isNotEmpty ? ud.imageBase64! : (info.base64Content ?? '');
    return b64.isEmpty ? null : base64Decode(b64);
  }

  /// 현재 항목이 렌더 준비 완료인지 판별합니다.
  bool isCurrentReady() => currentRenderable() != null;

  /// 뷰어에서 사용할 렌더 소스를 반환합니다. 준비되지 않았으면 `null`.
  /// - 이미지: `String`(Blob/HTTP URL) 또는 `Uint8List`
  /// - JSON:   `Map`/`List`
  /// - CSV:    `List<double>` (비어 있으면 null)
  Object? currentRenderable() {
    if (isEmpty) return null;
    final ud = currentData;
    switch (ud.fileType) {
      case FileType.image:
        final url = _urlCache[ud.dataId];
        if (url != null && url.isNotEmpty) return url;
        return _bytesCache[ud.dataId];
      case FileType.object:
        return ud.objectData;
      case FileType.series:
        final s = ud.seriesData;
        return (s == null || s.isEmpty) ? null : s;
      default:
        return null;
    }
  }

  // ───────────────────────────────────────────
  // 🔀 Navigation
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
  // ♻️ Lifecycle
  // ───────────────────────────────────────────

  /// 보유 중인 Blob URL을 해제하고 캐시를 비웁니다.
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

  bool get isLoaded => _isLoaded;
  bool get isEmpty => _dataList.isEmpty;
  List<UnifiedData> get allData => _dataList;

  /// 현재 포커스된 데이터. 비어 있을 때 호출하면 [StateError].
  UnifiedData get currentData {
    if (isEmpty) throw StateError('LabelingDataManager has no data');
    return _dataList[_currentIndex];
  }

  int get totalCount => _dataList.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < totalCount - 1;
  bool get hasPrevious => _currentIndex > 0;
}
