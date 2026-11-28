// lib/src/features/label/view_models/labeling_view_model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

import '../logic/label_input_mapper.dart';
import '../use_cases/label_use_cases.dart';
import 'labeling_data_manager.dart';

/// 라벨링 화면 공통 ViewModel. 모드별 VM(분류/교차/세그멘테이션)이 상속합니다.
///
/// ### 단일 소스 원칙
/// - 데이터 목록·포커스·렌더 캐시: [dataManager]
/// - 라벨: [_labels] (dataId → LabelModel). 초기화 시 저장소에서 **한 번** 일괄 로드
/// - 상태: [_statuses] (dataId → LabelStatus). 라벨이 바뀐 항목만 **증분** 갱신
///
/// 라벨 변경은 [commitLabel] 한 곳을 거치며, 메모리 반영 → 알림 → 저장(1회) 순서로 처리합니다.
/// 생명주기(생성·초기화·dispose)는 Riverpod provider가 소유합니다(`labeling_providers.dart`).
abstract class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final LabelUseCases labelUseCases;
  final LabelingDataManager dataManager;
  final LabelInputMapper inputMapper;

  final Map<String, LabelModel> _labels = {};
  final Map<String, LabelStatus> _statuses = {};
  bool _initialized = false;
  bool _disposed = false;
  int _renderRequest = 0;
  bool _renderPending = false;

  LabelingViewModel({
    required this.project,
    required StorageHelperInterface storageHelper,
    required this.labelUseCases,
    LabelingDataManager? dataManager,
    LabelInputMapper? inputMapper,
  }) : dataManager = dataManager ?? LabelingDataManager(project: project, storageHelper: storageHelper),
       inputMapper = inputMapper ?? LabelInputMapper.forMode(project.mode);

  LabelingMode get mode => project.mode;
  bool get isInitialized => _initialized;
  bool get isDisposed => _disposed;

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────

  /// 데이터 로드 → 라벨 일괄 로드 → 상태 계산 → 첫 항목 렌더 준비.
  Future<void> initialize() async {
    await dataManager.load();

    _labels
      ..clear()
      ..addAll(await labelUseCases.loadMap(project.id));
    _statuses.clear();
    for (final info in dataManager.dataInfos) {
      _statuses[info.id] = labelUseCases.statusOf(project, _labels[info.id]);
    }

    await postInitialize();
    await _prepareCurrentRender();
    _initialized = true;
    notify();
  }

  /// 초기화 직후 모드별 추가 작업(예: 교차 쌍 생성).
  @protected
  Future<void> postInitialize() async {}

  /// 포커스 이동 직후 모드별 추가 작업.
  @protected
  Future<void> postMove() async {}

  @override
  void dispose() {
    _disposed = true;
    dataManager.dispose();
    super.dispose();
  }

  /// dispose 이후 늦게 끝난 비동기 작업이 알림을 보내지 않도록 보호합니다.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────────────────────────────────────────

  bool get hasNext => dataManager.hasNext;
  bool get hasPrevious => dataManager.hasPrevious;

  Future<void> moveNext() => _moveTo(dataManager.moveNext, canMove: hasNext);
  Future<void> movePrevious() => _moveTo(dataManager.movePrevious, canMove: hasPrevious);
  Future<void> jumpTo(int index) => _moveTo(() => dataManager.jumpTo(index), canMove: index != dataManager.currentIndex);

  Future<void> _moveTo(void Function() move, {required bool canMove}) async {
    if (!canMove) return;
    move();
    await refreshCurrentItem();
  }

  /// 포커스가 바뀐 뒤 호출합니다: 즉시 알림(뷰어는 로딩 표시) → 현재 항목 준비 → [postMove] → 알림.
  @protected
  Future<void> refreshCurrentItem() async {
    _renderPending = true;
    notify();
    await _prepareCurrentRender();
    await postMove();
    notify();
  }

  /// 현재 항목의 내용을 읽고 렌더 소스를 준비한 뒤, 주변을 백그라운드로 프리로드합니다.
  /// 여러 항목을 함께 보여주는 모드(교차 분류)는 override합니다.
  @protected
  Future<void> prepareCurrentItem() async {
    await dataManager.ensureRenderableReadyForCurrent();
    unawaited(dataManager.preloadAround());
  }

  /// 빠르게 연속 이동한 경우 마지막 요청만 pending 플래그를 해제합니다.
  Future<void> _prepareCurrentRender() async {
    final request = ++_renderRequest;
    _renderPending = true;
    try {
      await prepareCurrentItem();
    } catch (e) {
      debugPrint('[LabelingViewModel] render prepare failed: $e');
    } finally {
      if (request == _renderRequest) _renderPending = false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Labels
  // ──────────────────────────────────────────────────────────────────────────

  /// 저장된 라벨(없으면 null).
  LabelModel? savedLabelOf(String dataId) => _labels[dataId];

  /// 라벨(없으면 해당 모드의 빈 라벨).
  LabelModel labelOf(String dataId) => _labels[dataId] ?? LabelModelFactory.createNew(mode, dataId: dataId);

  /// 현재 포커스 데이터의 라벨. 데이터가 없으면 null.
  LabelModel? get currentLabel => dataManager.isEmpty ? null : labelOf(dataManager.currentInfo.id);

  /// 현재 포커스 데이터에 UI 입력을 반영합니다. (입력 → [inputMapper] → [commitLabel])
  Future<void> applyInput(dynamic input) async {
    if (dataManager.isEmpty) return;
    final info = dataManager.currentInfo;
    final dataPath = info.filePath ?? '';
    await commitLabel(
      info.id,
      inputMapper.map(input, dataId: info.id, dataPath: dataPath),
      dataPath: dataPath,
    );
  }

  /// 라벨 변경의 **유일한 진입점**: 메모리 반영 → 상태 증분 갱신 → 알림 → 저장 1회.
  @protected
  Future<void> commitLabel(String dataId, LabelModel model, {String dataPath = ''}) async {
    _labels[dataId] = model;
    if (_statuses.containsKey(dataId)) {
      _statuses[dataId] = labelUseCases.statusOf(project, model);
    }
    notify();
    await labelUseCases.save(projectId: project.id, dataId: dataId, dataPath: dataPath, model: model);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Progress (데이터 단위 기본 구현. 교차 분류는 쌍 단위로 override)
  // ──────────────────────────────────────────────────────────────────────────

  LabelStatus statusOf(String dataId) => _statuses[dataId] ?? LabelStatus.incomplete;

  int get totalCount => dataManager.totalCount;
  int get currentIndex => dataManager.currentIndex;
  int get completeCount => _statuses.values.where((s) => s == LabelStatus.complete).length;
  int get warningCount => _statuses.values.where((s) => s == LabelStatus.warning).length;
  int get incompleteCount => totalCount - completeCount;
  double get progressRatio => totalCount == 0 ? 0.0 : completeCount / totalCount;

  /// 진행 표시줄에 보일 현재 항목 이름.
  String get currentItemName => dataManager.isEmpty ? '' : dataManager.currentInfo.fileName;

  // ──────────────────────────────────────────────────────────────────────────
  // Data / Render
  // ──────────────────────────────────────────────────────────────────────────

  /// 현재 항목의 내용(아직 읽는 중이면 내용 없는 항목).
  UnifiedData get currentData => dataManager.currentData;
  bool get isEmpty => dataManager.isEmpty;

  /// 현재 아이템의 렌더 소스(String URL | Uint8List | Map/List | null).
  Object? currentRenderable() => dataManager.currentRenderable();

  /// 현재 아이템의 렌더 소스를 준비 중인지. 준비가 끝났는데도 소스가 없으면 뷰어가 자체 fallback으로 그립니다.
  bool get isRenderPending => _renderPending;

  // ──────────────────────────────────────────────────────────────────────────
  // Export
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> exportAllLabels() => labelUseCases.exportProjectLabels(project.id, withData: true);
}
