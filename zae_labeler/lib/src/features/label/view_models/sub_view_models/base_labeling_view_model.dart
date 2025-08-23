// 📁 lib/src/features/label/view_models/sub_view_models/base_labeling_view_model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/use_cases/app_use_cases.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

import 'package:zae_labeler/src/features/label/view_models/managers/labeling_data_manager.dart';
import 'package:zae_labeler/src/features/label/view_models/managers/labeling_label_manager.dart';
import 'package:zae_labeler/src/features/label/view_models/label_view_model.dart' show LabelViewModel; // 타입만 사용

import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart' show LabelingSummary;

/// 공통 라벨링 화면 VM (분류/세그멘테이션이 상속)
/// - 데이터 로딩/네비게이션(LabelingDataManager)
/// - 라벨 단건 VM 캐시/IO(LabelingLabelManager)
/// - 진행 요약(LabelingSummary) 캐시
abstract class LabelingViewModel extends ChangeNotifier {
  // ──────────────────────────────────────────────────────────────────────────
  // DI
  // ──────────────────────────────────────────────────────────────────────────
  final Project project;
  final StorageHelperInterface storageHelper;
  final AppUseCases appUseCases;

  // ──────────────────────────────────────────────────────────────────────────
  // Managers
  // ──────────────────────────────────────────────────────────────────────────
  late final LabelingDataManager dataManager;
  late final LabelingLabelManager labelManager;

  // ──────────────────────────────────────────────────────────────────────────
  // Summary cache
  // ──────────────────────────────────────────────────────────────────────────
  LabelingSummary _summary = const LabelingSummary(total: 0, complete: 0, warning: 0, incomplete: 0, progress: 0.0);

  LabelingViewModel({required this.project, required this.storageHelper, required this.appUseCases}) {
    dataManager = LabelingDataManager(project: project, storageHelper: storageHelper);
    labelManager = LabelingLabelManager(project: project, appUseCases: appUseCases, onNotify: notifyListeners);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────────────
  /// 데이터 로드 + 첫 아이템 라벨 VM 생성 + 요약 계산
  Future<void> initialize() async {
    await dataManager.load();
    if (dataManager.totalCount > 0) {
      await labelManager.loadLabelFor(dataManager.currentData);
    }

    // ✅ 현재 아이템 렌더 소스 준비(Blob URL 생성 또는 bytes 디코드)
    await dataManager.ensureRenderableReadyForCurrent();
    // ✅ 다음/이전 한 칸 프리로드(있다면)
    unawaited(dataManager.preloadAround());

    await recomputeSummary();
    await postInitialize();
    notifyListeners();
  }

  /// 세부 VM에서 초기화 이후 추가 작업이 필요할 때 오버라이드
  Future<void> postInitialize() async {}

  /// 현재 index 변경 후(다음/이전/점프) 공통 처리
  Future<void> postMove() async {
    if (dataManager.totalCount > 0) {
      await labelManager.loadLabelFor(dataManager.currentData);
    }

    // ✅ 현재 아이템 렌더 소스 준비 + 프리로드
    await dataManager.ensureRenderableReadyForCurrent();
    unawaited(dataManager.preloadAround());

    await recomputeSummary();
    notifyListeners();
  }

  @override
  void dispose() {
    // ✅ Blob URL/임시 캐시 해제까지 함께 수행
    dataManager.dispose();
    labelManager.disposeAll();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> moveNext() async {
    if (!hasNext) return;
    dataManager.moveNext();
    await postMove();
  }

  Future<void> movePrevious() async {
    if (!hasPrevious) return;
    dataManager.movePrevious();
    await postMove();
  }

  Future<void> jumpTo(int index) async {
    dataManager.jumpTo(index);
    await postMove();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Label updates
  // ──────────────────────────────────────────────────────────────────────────
  /// 단건 라벨 입력 갱신(분류/세그멘테이션 공통 루트)
  Future<void> updateLabel(dynamic labelData) async {
    final vm = labelManager.currentLabelVM;
    if (vm == null) return;

    await vm.updateLabelFromInput(labelData);
    await vm.saveLabel();

    await recomputeSummary();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Summary
  // ──────────────────────────────────────────────────────────────────────────
  @protected
  Future<void> recomputeSummary() async {
    _summary = await appUseCases.label.computeSummaryByProject(project);
  }

  double get progressRatio => _summary.progress;
  int get completeCount => _summary.complete;
  int get warningCount => _summary.warning;
  int get incompleteCount => _summary.incomplete;

  // ──────────────────────────────────────────────────────────────────────────
  // Export
  // ──────────────────────────────────────────────────────────────────────────
  /// 현재 프로젝트 라벨 전체 내보내기(원본 데이터 동반)
  Future<String> exportAllLabels() async {
    return await appUseCases.label.exportProjectLabels(project.id, withData: true);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────────────────
  List<UnifiedData> get unifiedDataList => dataManager.allData;
  UnifiedData get currentData => dataManager.currentData;

  LabelViewModel? get currentLabelVM => labelManager.currentLabelVM;

  int get totalCount => dataManager.totalCount;
  int get currentIndex => dataManager.currentIndex;
  bool get hasNext => dataManager.hasNext;
  bool get hasPrevious => dataManager.hasPrevious;

  // ──────────────────────────────────────────────────────────────────────────
  // Render source (Blob URL or Bytes) - DataManager 위임
  // ──────────────────────────────────────────────────────────────────────────
  /// 현재 인덱스 아이템을 뷰어가 바로 쓸 수 있게 준비(Blob URL 생성 or Bytes 디코드)
  Future<void> ensureRenderableReadyForCurrent() {
    return dataManager.ensureRenderableReadyForCurrent();
  }

  /// 현재 아이템의 렌더 소스 반환
  /// - String: Blob/HTTP URL
  /// - Uint8List: 메모리 바이트
  /// - null: 아직 준비되지 않음(초기 로딩)
  Object? currentRenderable() {
    return dataManager.currentRenderable();
  }

  /// (옵션) ±1 프리로드를 외부에서 트리거하고 싶을 때 사용
  Future<void> preloadAround() {
    return dataManager.preloadAround();
  }
}
