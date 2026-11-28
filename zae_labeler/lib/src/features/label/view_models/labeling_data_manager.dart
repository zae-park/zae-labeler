// lib/src/features/label/view_models/labeling_data_manager.dart
import 'dart:collection';
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
/// 단일 프로젝트의 **데이터 목록, 포커스 인덱스, 콘텐츠/렌더 캐시**를 관리합니다.
/// 라벨과 라벨 상태는 다루지 않습니다(→ `LabelingViewModel`이 단일 소스로 관리).
///
/// ### 지연 로딩
/// - 목록은 가벼운 [DataInfo]만 보유합니다. 파일 내용(이미지/CSV/JSON)은 필요할 때 1건씩 읽습니다.
/// - 현재 항목과 앞뒤 [preloadRadius]개를 미리 읽고, 최근 사용 [cacheSize]개만 메모리에 유지합니다(LRU).
///   데이터가 수천 개여도 진입 시간·메모리가 데이터 수에 비례하지 않습니다.
/// - 같은 항목을 동시에 요청하면 한 번만 읽습니다.
///
/// ### 렌더 준비 우선순위 (이미지 한정)
/// 1) `UnifiedData.imageBase64` → 2) `DataInfo.base64Content` → 3) `ensureLocalObjectUrl` → 4) http(s) 경로면 `readDataBytes`
class LabelingDataManager {
  final Project project;
  final StorageHelperInterface storageHelper;

  /// 외부에서 이미 읽은 데이터가 있으면 그대로 사용(테스트/프리패치용). 이 항목들은 다시 읽지 않습니다.
  final List<UnifiedData>? initialDataList;

  final AdaptiveUnifiedDataLoader? _injectedLoader;

  /// 실제로 파일을 읽을 때 처음 생성합니다(플랫폼 로더 생성 비용·의존성을 미룸).
  late final AdaptiveUnifiedDataLoader loader = _injectedLoader ?? AdaptiveUnifiedDataLoader(uds: UnifiedDataService(), storage: storageHelper);

  /// 메모리에 유지할 최대 항목 수(콘텐츠 + 렌더 캐시).
  final int cacheSize;

  /// 현재 항목 앞뒤로 미리 읽을 개수.
  final int preloadRadius;

  List<DataInfo> _infos = const [];
  final LinkedHashMap<String, UnifiedData> _loaded = LinkedHashMap();
  final Map<String, Future<UnifiedData>> _inflight = {};
  final Map<String, String> _urlCache = {};
  final Map<String, Uint8List> _bytesCache = {};
  int _currentIndex = 0;
  bool _isLoaded = false;
  bool _disposed = false;

  LabelingDataManager({
    required this.project,
    required this.storageHelper,
    this.initialDataList,
    AdaptiveUnifiedDataLoader? loader,
    this.cacheSize = 16,
    this.preloadRadius = 1,
  }) : assert(cacheSize > 2 * preloadRadius),
       _injectedLoader = loader;

  // ───────────────────────────────────────────
  // 🚚 Load
  // ───────────────────────────────────────────

  /// 목록만 준비합니다(파일 내용은 읽지 않음).
  Future<void> load() async {
    final initial = initialDataList;
    _infos = List.unmodifiable(initial != null ? [for (final d in initial) d.dataInfo] : project.dataInfos);
    _loaded.clear();
    for (final d in initial ?? const <UnifiedData>[]) {
      _loaded[d.dataId] = d;
    }
    _currentIndex = 0;
    _isLoaded = true;
  }

  /// [dataId]의 내용을 읽어 캐시에 넣고 돌려줍니다. 이미 있으면 그대로, 읽는 중이면 그 결과를 기다립니다.
  /// 읽기에 실패하면 내용 없는 항목(unsupported)을 돌려줍니다.
  Future<UnifiedData> ensureLoaded(String dataId) {
    final cached = _loaded.remove(dataId);
    if (cached != null) {
      _loaded[dataId] = cached; // LRU touch
      return Future.value(cached);
    }
    return _inflight[dataId] ??= _fetch(dataId);
  }

  Future<UnifiedData> _fetch(String dataId) async {
    final info = infoFor(dataId);
    try {
      final data = await loader.loadOne(info);
      if (!_disposed) {
        _loaded[dataId] = data;
        _evict();
      }
      return data;
    } catch (e) {
      debugPrint('[LabelingDataManager] load failed for ${info.fileName}: $e');
      return _shell(info);
    } finally {
      _inflight.remove(dataId);
    }
  }

  /// 오래된 항목부터 내보냅니다. 현재 항목 주변(프리로드 범위)은 보호합니다.
  void _evict() {
    if (_loaded.length <= cacheSize) return;
    final protected = {for (final i in _window()) _infos[i].id};
    for (final id in _loaded.keys.toList()) {
      if (_loaded.length <= cacheSize) break;
      if (protected.contains(id)) continue;
      _loaded.remove(id);
      _bytesCache.remove(id);
      final url = _urlCache.remove(id);
      // ignore: discarded_futures
      if (url != null) storageHelper.revokeLocalObjectUrl(url);
    }
  }

  Iterable<int> _window() sync* {
    for (int i = _currentIndex - preloadRadius; i <= _currentIndex + preloadRadius; i++) {
      if (i >= 0 && i < _infos.length) yield i;
    }
  }

  // ───────────────────────────────────────────
  // 🖼️ Render readiness
  // ───────────────────────────────────────────

  /// 현재 항목의 내용을 읽고, 뷰어가 바로 쓸 수 있도록 렌더 소스를 준비합니다.
  Future<void> ensureRenderableReadyForCurrent() async {
    if (isEmpty) return;
    await _prepare(await ensureLoaded(currentInfo.id));
  }

  /// 주변 항목(±[preloadRadius])을 미리 읽고 렌더 소스를 준비합니다.
  Future<void> preloadAround() async {
    final ids = [
      for (final i in _window())
        if (i != _currentIndex) _infos[i].id,
    ];
    await Future.wait(
      ids.map((id) async {
        try {
          await _prepare(await ensureLoaded(id));
        } catch (e) {
          debugPrint('[LabelingDataManager] preload failed for $id: $e');
        }
      }),
    );
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
    final ud = _loaded[currentInfo.id];
    if (ud == null) return null;
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
    if (index >= 0 && index < _infos.length) _currentIndex = index;
  }

  // ───────────────────────────────────────────
  // ♻️ Lifecycle
  // ───────────────────────────────────────────

  /// 보유 중인 Blob URL을 해제하고 캐시를 비웁니다.
  void dispose() {
    _disposed = true;
    for (final u in _urlCache.values) {
      // ignore: discarded_futures
      storageHelper.revokeLocalObjectUrl(u);
    }
    _urlCache.clear();
    _bytesCache.clear();
    _loaded.clear();
  }

  // ───────────────────────────────────────────
  // 🔎 Getters
  // ───────────────────────────────────────────

  bool get isLoaded => _isLoaded;
  bool get isEmpty => _infos.isEmpty;

  /// 전체 데이터 목록(메타데이터만).
  List<DataInfo> get dataInfos => _infos;

  DataInfo infoFor(String dataId) => _infos.firstWhere((e) => e.id == dataId);

  /// 메모리에 올라와 있는 항목 수(테스트/진단용).
  int get loadedCount => _loaded.length;
  bool isContentLoaded(String dataId) => _loaded.containsKey(dataId);

  /// [dataId]의 내용. 아직 읽지 않았으면 내용 없는 항목(unsupported)을 돌려줍니다.
  UnifiedData dataFor(String dataId) => _loaded[dataId] ?? _shell(infoFor(dataId));

  UnifiedData _shell(DataInfo info) => UnifiedData(dataInfo: info, fileType: FileType.unsupported);

  DataInfo get currentInfo {
    if (isEmpty) throw StateError('LabelingDataManager has no data');
    return _infos[_currentIndex];
  }

  /// 현재 포커스된 데이터(아직 읽는 중이면 내용 없는 항목). 비어 있을 때 호출하면 [StateError].
  UnifiedData get currentData => dataFor(currentInfo.id);

  int get totalCount => _infos.length;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < totalCount - 1;
  bool get hasPrevious => _currentIndex > 0;
}
